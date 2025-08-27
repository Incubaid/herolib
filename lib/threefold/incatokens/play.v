module incatokens

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.pathlib
import os

pub fn play(mut plbook PlayBook) ! {
	console.print_header('INCA Token Simulation')

	// Process simulation definitions
	for action in plbook.find(filter: 'incatokens.simulate')! {
		mut p := action.params

		// Create parameters struct
		mut params := SimulationParams{
			name: p.get_default('name', 'inca_simulation')!
		}

		// Configure token distribution
		params.distribution.total_supply = p.get_float_default('total_supply', 10_000_000_000.0)!
		params.distribution.public_pct = p.get_float_default('public_pct', 0.50)!
		params.distribution.team_pct = p.get_float_default('team_pct', 0.15)!
		params.distribution.treasury_pct = p.get_float_default('treasury_pct', 0.15)!
		params.distribution.investor_pct = p.get_float_default('investor_pct', 0.20)!

		// Configure simulation settings
		params.simulation.nrcol = p.get_int_default('nrcol', 60)!
		params.simulation.currency = p.get_default('currency', 'USD')!

		// Configure economics
		params.economics.epoch1_floor_uplift = p.get_float_default('epoch1_floor_uplift', 1.20)!
		params.economics.epochn_floor_uplift = p.get_float_default('epochn_floor_uplift', 1.20)!
		params.economics.amm_liquidity_depth_factor = p.get_float_default('amm_liquidity_depth_factor', 2.0)!

		// Configure vesting
		params.vesting.team.cliff_months = p.get_int_default('team_cliff_months', 12)!
		params.vesting.team.vesting_months = p.get_int_default('team_vesting_months', 36)!
		params.vesting.treasury.cliff_months = p.get_int_default('treasury_cliff_months', 12)!
		params.vesting.treasury.vesting_months = p.get_int_default('treasury_vesting_months', 48)!

		// Configure output
		params.output.export_dir = p.get_default('export_dir', './output')!
		params.output.generate_csv = p.get_default_true('generate_csv')
		params.output.generate_charts = p.get_default_true('generate_charts')
		params.output.generate_report = p.get_default_true('generate_report')

		console.print_item('Running simulation: ${params.name}')
		
		// Run the simulation
		params.run_simulation()!
		
		console.print_green('✓ Simulation completed successfully')
	}

	// Process investor round definitions
	for action in plbook.find(filter: 'incatokens.investor_round')! {
		mut p := action.params
		
		round := InvestorRoundConfig{
			name: p.get('name')!
			allocation_pct: p.get_float('allocation_pct')!
			price: p.get_float('price')!
			vesting: VestingConfig{
				cliff_months: p.get_int('cliff_months')!
				vesting_months: p.get_int('vesting_months')!
			}
		}
		
		console.print_item('Configured investor round: ${round.name} at \$${round.price}')
	}

	// Process scenario definitions
	for action in plbook.find(filter: 'incatokens.scenario')! {
		mut p := action.params
		
		scenario := ScenarioConfig{
			name: p.get('name')!
			demands: p.get_list_f64('demands')!
			amm_trades: p.get_list_f64('amm_trades')!
		}
		
		console.print_item('Configured scenario: ${scenario.name}')
	}
}