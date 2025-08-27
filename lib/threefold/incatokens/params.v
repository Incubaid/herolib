module incatokens
import os

// TokenDistribution defines how tokens are allocated across different categories
pub struct TokenDistribution {
pub mut:
	total_supply f64 = 10_000_000_000
	public_pct   f64 = 0.50
	team_pct     f64 = 0.15
	treasury_pct f64 = 0.15
	investor_pct f64 = 0.20
}

// VestingConfig defines cliff and vesting periods
pub struct VestingConfig {
pub mut:
	cliff_months   int
	vesting_months int
}

// InvestorRoundConfig defines parameters for each investment round
pub struct InvestorRoundConfig {
pub mut:
	name           string
	allocation_pct f64
	price          f64
	vesting        VestingConfig
}

// EconomicsConfig defines economic parameters affecting token pricing
pub struct EconomicsConfig {
pub mut:
	epoch1_floor_uplift        f64 = 1.20
	epochn_floor_uplift        f64 = 1.20
	amm_liquidity_depth_factor f64 = 2.0
}

// VestingConfigs groups all vesting configurations
pub struct VestingConfigs {
pub mut:
	team     VestingConfig
	treasury VestingConfig
}

// SimulationConfig defines technical simulation parameters
pub struct SimulationConfig {
pub mut:
	nrcol    int    = 60    // Number of months to simulate
	currency string = 'USD'
}

// ScenarioConfig defines a single scenario with market conditions
pub struct ScenarioConfig {
pub mut:
	name       string
	demands    []f64
	amm_trades []f64
}

// OutputConfig defines where and how to generate outputs
pub struct OutputConfig {
pub mut:
	export_dir     string = './output'
	generate_csv   bool   = true
	generate_charts bool  = true
	generate_report bool  = true
}

// SimulationParams is the main configuration struct containing all parameters
pub struct SimulationParams {
pub mut:
	name            string
	distribution    TokenDistribution
	investor_rounds []InvestorRoundConfig
	vesting         VestingConfigs
	economics       EconomicsConfig
	simulation      SimulationConfig
	scenarios       []ScenarioConfig
	output          OutputConfig
}

// run_simulation executes the simulation with the given parameters
pub fn (params SimulationParams) run_simulation() ! {
	mut sim := simulation_new(
		name: params.name
		total_supply: params.distribution.total_supply
		public_pct: params.distribution.public_pct
		team_pct: params.distribution.team_pct
		treasury_pct: params.distribution.treasury_pct
		investor_pct: params.distribution.investor_pct
		nrcol: params.simulation.nrcol
		currency: params.simulation.currency
	)!

	// Configure economics
	sim.epoch1_floor_uplift = params.economics.epoch1_floor_uplift
	sim.epochn_floor_uplift = params.economics.epochn_floor_uplift
	sim.amm_liquidity_depth_factor = params.economics.amm_liquidity_depth_factor

	// Set up investor rounds
	sim.investor_rounds = params.investor_rounds.map(InvestorRound{
		name: it.name
		allocation_pct: it.allocation_pct
		price: it.price
		vesting: VestingSchedule{
			cliff_months: it.vesting.cliff_months
			vesting_months: it.vesting.vesting_months
		}
	})

	// Set up vesting schedules
	sim.team_vesting = VestingSchedule{
		cliff_months: params.vesting.team.cliff_months
		vesting_months: params.vesting.team.vesting_months
	}
	sim.treasury_vesting = VestingSchedule{
		cliff_months: params.vesting.treasury.cliff_months
		vesting_months: params.vesting.treasury.vesting_months
	}

	// Run scenarios
	for scenario in params.scenarios {
		sim.run_scenario(scenario.name, scenario.demands, scenario.amm_trades)!
	}

	// Generate vesting schedules
	sim.create_vesting_schedules()!

	// Generate outputs
	if params.output.generate_csv {
		os.mkdir_all(params.output.export_dir)!
		sim.export_csv('prices', '${params.output.export_dir}/${params.name}_prices.csv')!
		sim.export_csv('tokens', '${params.output.export_dir}/${params.name}_tokens.csv')!
		sim.export_csv('investments', '${params.output.export_dir}/${params.name}_investments.csv')!
		sim.export_csv('vesting', '${params.output.export_dir}/${params.name}_vesting.csv')!
	}

	if params.output.generate_report {
		sim.generate_report(params.output.export_dir)!
	}
}