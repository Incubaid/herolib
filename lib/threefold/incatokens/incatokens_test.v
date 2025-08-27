module incatokens

import os

fn test_simulation_creation() {
	mut params := default_params()
	params.name = 'test_sim_creation'
	
	mut sim := simulation_new_from_params(params)!
	
	assert sim.name == 'test_sim_creation'
	assert sim.total_supply == params.distribution.total_supply
	assert sim.investor_rounds.len == params.investor_rounds.len
}

fn test_scenario_execution() {
	mut params := default_params()
	params.name = 'test_scenario_exec'
	
	mut sim := simulation_new_from_params(params)!
	sim.run_full_simulation(params)!
	
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
	
	mut sim := simulation_new_from_params(params)!
	sim.run_full_simulation(params)!
	
	// Check team vesting
	team_row := sim.vesting_sheet.row_get('team_vesting')!
	
	// Before cliff (month 11), should be 0
	assert team_row.cells[11].val == 0
	
	// After cliff starts (month 12), should have tokens
	assert team_row.cells[12].val > 0
	
	// After full vesting (month 48), should have all tokens
	total_team_tokens := sim.total_supply * sim.team_pct
	assert team_row.cells[48].val == total_team_tokens
}

fn test_export_functionality() {
	mut params := default_params()
	params.name = 'test_export'
	params.output.export_dir = '/tmp/incatokens_test_output'
	params.output.generate_csv = true
	params.output.generate_report = true
	
	// Ensure output directory exists and is clean
	os.rmdir_all(params.output.export_dir) or {}
	os.mkdir_all(params.output.export_dir)!
	
	mut sim := simulation_new_from_params(params)!
	sim.run_full_simulation(params)!
	
	// Test CSV export (already handled by run_full_simulation if generate_csv is true)
	assert os.exists('${params.output.export_dir}/${params.name}_prices.csv')
	assert os.exists('${params.output.export_dir}/${params.name}_tokens.csv')
	assert os.exists('${params.output.export_dir}/${params.name}_investments.csv')
	assert os.exists('${params.output.export_dir}/${params.name}_vesting.csv')
	
	// Test report generation (already handled by run_full_simulation if generate_report is true)
	assert os.exists('${params.output.export_dir}/${params.name}_report.md')
}