module incatokens

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.pathlib
import os

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'incatokens.') {
		return
	}
	console.print_header('INCA Token Simulation')

	// Collect all configurations first
	mut simulations_to_run := []SimulationParams{}
	mut export_path := ''

	// Process export configuration
	if plbook.exists_once(filter: 'incatokens.export') {
		mut action := plbook.get(filter: 'incatokens.export')!
		mut p := action.params
		export_path = p.get('path')!
		console.print_item('Export directory configured: ${export_path}')
	}

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
		params.economics.epoch1_floor_uplift = p.get_float_default('epoch1_floor_uplift',
			1.20)!
		params.economics.epochn_floor_uplift = p.get_float_default('epochn_floor_uplift',
			1.20)!
		params.economics.amm_liquidity_depth_factor = p.get_float_default('amm_liquidity_depth_factor',
			2.0)!

		// Configure vesting
		params.vesting.team.cliff_months = p.get_int_default('team_cliff_months', 12)!
		params.vesting.team.vesting_months = p.get_int_default('team_vesting_months',
			36)!
		params.vesting.treasury.cliff_months = p.get_int_default('treasury_cliff_months',
			12)!
		params.vesting.treasury.vesting_months = p.get_int_default('treasury_vesting_months',
			48)!

		// Configure output - use export_path if provided, otherwise use param
		if export_path != '' {
			params.output.export_dir = export_path
		} else {
			params.output.export_dir = p.get_default('export_dir', './output')!
		}
		params.output.generate_csv = p.get_default_true('generate_csv')
		params.output.generate_charts = p.get_default_true('generate_charts')
		params.output.generate_report = p.get_default_true('generate_report')

		// Collect investor rounds for this simulation
		mut investor_rounds := []InvestorRoundConfig{}
		for round_action in plbook.find(filter: 'incatokens.investor_round')! {
			mut rp := round_action.params

			round := InvestorRoundConfig{
				name:           rp.get('name')!
				allocation_pct: rp.get_float('allocation_pct')!
				price:          rp.get_float('price')!
				vesting:        VestingConfig{
					cliff_months:   rp.get_int('cliff_months')!
					vesting_months: rp.get_int('vesting_months')!
				}
			}
			investor_rounds << round
			console.print_item('Configured investor round: ${round.name} at \$${round.price}')
		}
		params.investor_rounds = investor_rounds

		// Collect scenarios for this simulation
		mut scenarios := []ScenarioConfig{}
		for scenario_action in plbook.find(filter: 'incatokens.scenario')! {
			mut sp := scenario_action.params

			scenario := ScenarioConfig{
				name:       sp.get('name')!
				demands:    sp.get_list_f64('demands')!
				amm_trades: sp.get_list_f64('amm_trades')!
			}
			scenarios << scenario
			console.print_item('Configured scenario: ${scenario.name}')
		}
		params.scenarios = scenarios

		simulations_to_run << params
	}

	// Run all simulations
	for params in simulations_to_run {
		console.print_item('Running simulation: ${params.name}')

		// Create and run simulation
		mut sim := simulation_new(params)!
		sim.run_simulation()!

		// Create export directory if needed
		os.mkdir_all(params.output.export_dir)!

		// Export all data in one call
		sim.export_all(params.output.export_dir)!

		console.print_green('✓ Simulation "${params.name}" completed and exported to: ${params.output.export_dir}')
	}
}
