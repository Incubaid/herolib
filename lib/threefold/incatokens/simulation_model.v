module incatokens

import freeflowuniverse.herolib.biz.spreadsheet

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
pub:
	params SimulationParams //all config info comes here
pub mut:
	name string

	//THE DATA WE ACTIVELY NEED TO SIMULATE IS HERE
		
	// Tracking sheets
	price_sheet &spreadsheet.Sheet
	token_sheet &spreadsheet.Sheet
	investment_sheet &spreadsheet.Sheet
	vesting_sheet &spreadsheet.Sheet
	
	// Scenarios
	scenarios map[string]&Scenario
}