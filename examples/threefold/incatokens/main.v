import freeflowuniverse.herolib.threefold.incatokens

fn main() {
	// Create simulation
	mut sim := incatokens.simulation_new(
		name: 'inca_tge_v1'
		total_supply: 10_000_000_000
	)!
	
	// Initialize with default rounds
	sim.init_default_rounds()!
	
	// Define scenarios
	scenarios := {
		'Low': {
			'demands': [10_000_000.0, 10_000_000.0, 0.0],
			'amm_trades': [0.0, 0.0, 0.0]
		},
		'Mid': {
			'demands': [20_000_000.0, 20_000_000.0, 0.0],
			'amm_trades': [0.0, 0.0, 0.0]
		},
		'High': {
			'demands': [50_000_000.0, 100_000_000.0, 0.0],
			'amm_trades': [0.0, 0.0, 0.0]
		}
	}
	
	// Run all scenarios
	for name, params in scenarios {
		sim.run_scenario(name, params['demands'], params['amm_trades'])!
	}
	
	// Create vesting schedules
	sim.create_vesting_schedules()!
	
	// Generate charts
	price_chart := sim.generate_price_chart()!
	market_cap_chart := sim.generate_market_cap_chart()!
	vesting_chart := sim.generate_vesting_chart()!
	
	// Export results
	sim.export_report('simulation_report.md')!
	sim.export_csv('prices', 'price_data.csv')!
	sim.export_csv('vesting', 'vesting_schedule.csv')!
	
	println('Simulation complete!')
}