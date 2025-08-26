module incatokens

fn test_simulation_creation() {
	mut sim := simulation_new(name: 'test_sim')!
	sim.init_default_rounds()!
	
	assert sim.name == 'test_sim'
	assert sim.total_supply == 10_000_000_000
	assert sim.investor_rounds.len == 3
}

fn test_scenario_execution() {
	mut sim := simulation_new(name: 'test_sim')!
	sim.init_default_rounds()!
	
	// Run low scenario
	low_scenario := sim.run_scenario(
		'Low',
		[10_000_000.0, 10_000_000.0, 0.0],
		[0.0, 0.0, 0.0]
	)!
	
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
	mut sim := simulation_new(name: 'test_sim')!
	sim.init_default_rounds()!
	sim.create_vesting_schedules()!
	
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
	mut sim := simulation_new(name: 'test_export')!
	sim.init_default_rounds()!
	
	// Run scenarios
	sim.run_scenario('Low', [10_000_000.0, 10_000_000.0, 0.0], [0.0, 0.0, 0.0])!
	sim.run_scenario('High', [50_000_000.0, 100_000_000.0, 0.0], [0.0, 0.0, 0.0])!
	
	// Test CSV export
	sim.export_csv('prices', '/tmp/test_prices.csv')!
	
	// Test report generation
	// sim.export_report('/tmp/test_report.md')!
}
// fn test_template_rendering() {
// 	mut sim := simulation_new(name: 'test_template')!
// 	sim.init_default_rounds()!
	
// 	// Run a scenario
// 	sim.run_scenario('Low', [10_000_000.0, 10_000_000.0, 0.0], [0.0, 0.0, 0.0])!
	
// 	// Render the report
// 	report := sim.render_report()!
	
// 	// Assert that the report is not empty and contains some expected text
// 	assert report.len > 0
// 	assert report.contains('# INCA TGE Simulation Report')
// 	assert report.contains('## 1) Token Distribution &amp; Vesting')
// }