module incatokens

import freeflowuniverse.herolib.biz.spreadsheet
import os
import incatokens.defaults
import incatokens.factory

fn test_simulation_creation() {
	mut params := default_params()
	params.name = 'test_sim_creation'

	mut sim := factory.simulation_new(params)!
	sim.run_simulation()! // Run the simulation

	assert sim.name == 'test_sim_creation'
	assert sim.params.distribution.total_supply == params.distribution.total_supply
	assert sim.investor_rounds.len == params.investor_rounds.len
}

fn test_scenario_execution() {
	mut params := default_params()
	params.name = 'test_scenario_exec'

	mut sim := factory.simulation_new(params)!
	sim.run_simulation()!

	// Get the 'Low' scenario results
	low_scenario := sim.scenarios['Low']!

	assert low_scenario.name == 'Low'
	assert low_scenario.final_metrics.treasury_total > 0
	assert low_scenario.final_metrics.final_price > 0

	// Check ROI is positive for all rounds
	for round in sim.investor_rounds {
		roi := low_scenario.final_metrics.investor_roi[round.name] or { 0.0 }
		assert roi > 0 // Should have positive return
	}
}

fn test_vesting_schedules() {
	mut params := default_params()
	params.name = 'test_vesting_schedules'

	mut sim := factory.simulation_new(params)!
	sim.run_simulation()!

	// Check team vesting
	team_row := sim.vesting_sheet.row_get('team_vesting')!

	// Before cliff (month 11), should be 0
	assert team_row.cells[11].val == 0

	// After cliff starts (month 12), should have tokens
	assert team_row.cells[12].val > 0

	// After full vesting (month 48), should have all tokens
	total_team_tokens := sim.params.distribution.total_supply * sim.params.distribution.team_pct
	assert team_row.cells[48].val == total_team_tokens
}

fn test_export_functionality() {
	mut params := default_params()
	params.name = 'test_export'
	params.output.export_dir = '/tmp/incatokens_test_output'
	params.output.generate_csv = true
	params.output.generate_report = true

	mut sim := factory.simulation_new(params)!
	sim.run_simulation()!

	// Ensure price sheet has data before export
	assert sim.price_sheet.rows.len > 0

	// Export all data
	os.mkdir_all(params.output.export_dir)!
	sim.export_all(params.output.export_dir)!

	// Test CSV export
	assert os.exists('${params.output.export_dir}/${params.name}_prices.csv')
	assert os.exists('${params.output.export_dir}/${params.name}_tokens.csv')
	assert os.exists('${params.output.export_dir}/${params.name}_investments.csv')
	assert os.exists('${params.output.export_dir}/${params.name}_vesting.csv')

	// Test report generation
	assert os.exists('${params.output.export_dir}/${params.name}_report.md')
}

fn test_direct_csv_export() {
	mut sheet := spreadsheet.sheet_new(
		name:  'test_sheet'
		nrcol: 2
		curr:  'USD'
	)!

	mut row := sheet.row_new(name: 'test_row')!
	row.cells[0].val = 100.0
	row.cells[1].val = 200.0

	export_path := '/tmp/test_direct_export.csv'
	os.rm(export_path) or {} // Clean up previous run

	sheet.export_csv(
		path:          export_path
		separator:     ','
		include_empty: false
	)!

	assert os.exists(export_path)
	os.rm(export_path) or {} // Clean up
}
