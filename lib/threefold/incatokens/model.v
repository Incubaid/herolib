module incatokens

import freeflowuniverse.herolib.biz.spreadsheet
import freeflowuniverse.herolib.data.ourtime

pub struct VestingSchedule {
pub mut:
	cliff_months int
	vesting_months int
}

pub struct InvestorRound {
pub mut:
	name string
	allocation_pct f64
	price f64
	vesting VestingSchedule
}

pub enum EpochType {
	auction_only
	hybrid
	amm_only
}

pub struct Epoch {
pub mut:
	index int
	type_ EpochType
	start_month int
	end_month int
	auction_share f64
	amm_share f64
	tokens_allocated f64
	tokens_spillover f64
	auction_demand f64
	amm_net_trade f64
	final_price f64
	treasury_raised f64
}

pub struct Scenario {
pub mut:
	name string
	demands []f64
	amm_trades []f64
	epochs []Epoch
	final_metrics ScenarioMetrics
}

pub struct ScenarioMetrics {
pub mut:
	treasury_total f64
	final_price f64
	investor_roi map[string]f64
	market_cap_final f64
	circulating_supply_final f64
}

@[heap]
pub struct Simulation {
pub mut:
	name string
	
	// Token distribution
	total_supply f64
	public_pct f64
	team_pct f64
	treasury_pct f64
	investor_pct f64
	
	// Configuration
	currency string
	epoch1_floor_uplift f64 = 1.20
	epochn_floor_uplift f64 = 1.20
	amm_liquidity_depth_factor f64 = 2.0
	
	// Investor rounds
	investor_rounds []InvestorRound
	
	// Vesting schedules
	team_vesting VestingSchedule
	treasury_vesting VestingSchedule
	
	// Tracking sheets
	price_sheet &spreadsheet.Sheet
	token_sheet &spreadsheet.Sheet
	investment_sheet &spreadsheet.Sheet
	vesting_sheet &spreadsheet.Sheet
	
	// Scenarios
	scenarios map[string]&Scenario
}