module incatokens

import freeflowuniverse.herolib.biz.spreadsheet

// Simulation holds the main simulation state
pub struct Simulation {
pub mut:
	// Core identification
	name string

	// Configuration (embedded)
	params SimulationParams

	// Derived data
	investor_rounds  []InvestorRound
	team_vesting     VestingSchedule
	treasury_vesting VestingSchedule

	// Runtime state
	scenarios map[string]&Scenario

	// Spreadsheets for tracking
	price_sheet      &spreadsheet.Sheet
	token_sheet      &spreadsheet.Sheet
	investment_sheet &spreadsheet.Sheet
	vesting_sheet    &spreadsheet.Sheet
}

// Main simulation runner - single entry point
pub fn (mut sim Simulation) run_simulation() ! {
	// Set up investor rounds from params
	sim.investor_rounds = sim.params.investor_rounds.map(InvestorRound{
		name:           it.name
		allocation_pct: it.allocation_pct
		price:          it.price
		vesting:        VestingSchedule{
			cliff_months:   it.vesting.cliff_months
			vesting_months: it.vesting.vesting_months
		}
	})

	// Set up vesting schedules from params
	sim.team_vesting = VestingSchedule{
		cliff_months:   sim.params.vesting.team.cliff_months
		vesting_months: sim.params.vesting.team.vesting_months
	}
	sim.treasury_vesting = VestingSchedule{
		cliff_months:   sim.params.vesting.treasury.cliff_months
		vesting_months: sim.params.vesting.treasury.vesting_months
	}

	// Run all scenarios from params
	for scenario_config in sim.params.scenarios {
		sim.run_scenario(scenario_config.name, scenario_config.demands, scenario_config.amm_trades)!
	}

	// Generate vesting schedules
	sim.create_vesting_schedules()!
}

// Run a scenario with given demands and AMM trades
pub fn (mut sim Simulation) run_scenario(name string, demands []f64, amm_trades []f64) !&Scenario {
	mut scenario := &Scenario{
		name:       name
		demands:    demands
		amm_trades: amm_trades
	}

	// Initialize epochs
	scenario.epochs = [
		Epoch{
			index:         0
			type_:         .auction_only
			start_month:   0
			end_month:     3
			auction_share: 1.0
			amm_share:     0.0
		},
		Epoch{
			index:         1
			type_:         .hybrid
			start_month:   3
			end_month:     6
			auction_share: 0.5
			amm_share:     0.5
		},
		Epoch{
			index:         2
			type_:         .amm_only
			start_month:   6
			end_month:     12
			auction_share: 0.0
			amm_share:     1.0
		},
	]

	// Track in spreadsheet
	mut price_row := sim.price_sheet.row_new(
		name:  'scenario_${name}_price'
		tags:  'scenario:${name} type:price'
		descr: 'Token price evolution for ${name} scenario'
	)!

	mut treasury_row := sim.investment_sheet.row_new(
		name:          'scenario_${name}_treasury'
		tags:          'scenario:${name} type:treasury'
		descr:         'Treasury raised for ${name} scenario'
		aggregatetype: .sum
	)!

	// Calculate public tokens per epoch
	total_public := sim.params.distribution.total_supply * sim.params.distribution.public_pct
	tokens_per_epoch := total_public / 3.0

	mut last_auction_price := sim.get_last_investor_price()
	mut spillover := 0.0
	mut treasury_total := 0.0
	mut amm_pool := AMMPool{}

	for mut epoch in scenario.epochs {
		epoch.tokens_allocated = tokens_per_epoch + spillover
		epoch.auction_demand = demands[epoch.index]
		epoch.amm_net_trade = amm_trades[epoch.index]

		// Run auction if applicable
		if epoch.auction_share > 0 {
			auction_tokens := epoch.tokens_allocated * epoch.auction_share
			floor_price := sim.calculate_floor_price(epoch.index, last_auction_price)

			auction_result := simulate_auction(
				demand:       epoch.auction_demand
				min_price:    floor_price
				token_supply: auction_tokens
			)!

			epoch.treasury_raised = auction_result.usd_raised
			treasury_total += auction_result.usd_raised
			last_auction_price = auction_result.clearing_price
			epoch.final_price = auction_result.clearing_price
			spillover = auction_tokens - auction_result.tokens_sold

			// Record in spreadsheet
			treasury_row.cells[epoch.start_month].val = auction_result.usd_raised
		}

		// Handle AMM if applicable
		if epoch.amm_share > 0 {
			amm_tokens := epoch.tokens_allocated * epoch.amm_share + spillover
			spillover = 0

			// Seed AMM pool
			amm_usdc_to_add := sim.params.economics.amm_liquidity_depth_factor * epoch.treasury_raised
			amm_pool.add_liquidity(amm_tokens, amm_usdc_to_add)

			// Simulate trading
			if epoch.amm_net_trade != 0 {
				amm_pool.trade(epoch.amm_net_trade)!
			}

			epoch.final_price = amm_pool.get_price()
		}

		// Record price in spreadsheet
		for month in epoch.start_month .. epoch.end_month {
			price_row.cells[month].val = epoch.final_price
		}

		epoch.tokens_spillover = spillover
	}

	// Calculate final metrics
	scenario.final_metrics = sim.calculate_metrics(scenario, treasury_total)!

	sim.scenarios[name] = scenario
	return scenario
}

// Calculate metrics for scenario
fn (sim Simulation) calculate_metrics(scenario &Scenario, treasury_total f64) !ScenarioMetrics {
	final_price := scenario.epochs.last().final_price

	mut investor_roi := map[string]f64{}
	for round in sim.investor_rounds {
		investor_roi[round.name] = final_price / round.price
	}

	return ScenarioMetrics{
		treasury_total:           treasury_total
		final_price:              final_price
		investor_roi:             investor_roi
		market_cap_final:         final_price * sim.params.distribution.total_supply
		circulating_supply_final: sim.calculate_circulating_supply(12) // at month 12
	}
}

fn (sim Simulation) get_last_investor_price() f64 {
	mut max_price := 0.0
	for round in sim.investor_rounds {
		if round.price > max_price {
			max_price = round.price
		}
	}
	return max_price
}

fn (sim Simulation) calculate_floor_price(epoch_idx int, last_auction_price f64) f64 {
	last_investor_price := sim.get_last_investor_price()

	if epoch_idx == 0 {
		return last_investor_price * sim.params.economics.epoch1_floor_uplift
	}
	return last_auction_price * sim.params.economics.epochn_floor_uplift
}

fn (sim Simulation) calculate_circulating_supply(month int) f64 {
	// Base circulation (non-public allocations)
	investor_tokens := sim.params.distribution.investor_pct * sim.params.distribution.total_supply
	team_tokens := sim.params.distribution.team_pct * sim.params.distribution.total_supply
	treasury_tokens := sim.params.distribution.treasury_pct * sim.params.distribution.total_supply

	// For simplicity, assume all public tokens are circulating after TGE
	public_tokens := sim.params.distribution.public_pct * sim.params.distribution.total_supply

	return investor_tokens + team_tokens + treasury_tokens + public_tokens
}

// Export all simulation data
pub fn (sim Simulation) export_all(export_dir string) ! {
	if sim.params.output.generate_csv {
		sim.export_csv('prices', '${export_dir}/${sim.name}_prices.csv')!
		sim.export_csv('tokens', '${export_dir}/${sim.name}_tokens.csv')!
		sim.export_csv('investments', '${export_dir}/${sim.name}_investments.csv')!
		sim.export_csv('vesting', '${export_dir}/${sim.name}_vesting.csv')!
	}

	if sim.params.output.generate_report {
		sim.generate_report(export_dir)!
	}
}
