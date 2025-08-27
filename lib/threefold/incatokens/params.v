module incatokens
import os


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
	cliff_months   int = 6
	vesting_months int = 24
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
	export_dir      string = './output'
	generate_csv    bool   = true
	generate_charts bool   = true
	generate_report bool   = true
}

