module incatokens

import freeflowuniverse.herolib.biz.spreadsheet

// VestingSchedule defines cliff and vesting periods
pub struct VestingSchedule {
pub mut:
	cliff_months       int
	vesting_months     int
	initial_unlock_pct f64 // Percentage of tokens unlocked at month 0
}

// InvestorRound represents an investment round
pub struct InvestorRound {
pub mut:
	name           string
	allocation_pct f64
	price          f64
	vesting        VestingSchedule
}

// Epoch represents a phase in the token release schedule
pub struct Epoch {
pub mut:
	index            int
	type_            EpochType
	start_month      int
	end_month        int
	auction_share    f64
	amm_share        f64
	tokens_allocated f64
	auction_demand   f64
	amm_net_trade    f64
	treasury_raised  f64
	final_price      f64
	tokens_spillover f64
}

pub enum EpochType {
	auction_only
	hybrid
	amm_only
}

// ScenarioMetrics holds the final results of a scenario
pub struct ScenarioMetrics {
pub mut:
	treasury_total           f64
	final_price              f64
	investor_roi             map[string]f64
	market_cap_final         f64
	circulating_supply_final f64
}

// Scenario represents a market scenario
pub struct Scenario {
pub mut:
	name          string
	demands       []f64
	amm_trades    []f64
	epochs        []Epoch
	final_metrics ScenarioMetrics
}
