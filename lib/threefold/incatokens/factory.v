module incatokens

import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.biz.spreadsheet

__global (
	simulations map[string]&Simulation
)

@[params]
pub struct SimulationNewArgs {
pub mut:
	// name of the simulation, used for identification and file naming
	name string = 'default'
	// total supply of INCA tokens
	total_supply f64 = 10_000_000_000
	// percentage of tokens allocated to public sale (TGE)
	public_pct f64 = 0.50
	// percentage of tokens allocated to the team
	team_pct f64 = 0.15
	// percentage of tokens allocated to the treasury
	treasury_pct f64 = 0.15
	// percentage of tokens allocated to investors
	investor_pct f64 = 0.20
	// number of columns (months) for the simulation spreadsheets
	nrcol int = 60 // 60 months default
	// currency used in the simulation (e.g., 'USD')
	currency string = 'USD'
}

pub fn simulation_new(args SimulationNewArgs) !&Simulation {
	name := texttools.name_fix(args.name)
	
	// Initialize spreadsheets for tracking
	price_sheet := spreadsheet.sheet_new(
		name: '${name}_prices'
		nrcol: args.nrcol
		curr: args.currency
	)!
	
	token_sheet := spreadsheet.sheet_new(
		name: '${name}_tokens'
		nrcol: args.nrcol
		curr: args.currency
	)!
	
	investment_sheet := spreadsheet.sheet_new(
		name: '${name}_investments'
		nrcol: args.nrcol
		curr: args.currency
	)!
	
	mut sim := &Simulation{
		name: name
		total_supply: args.total_supply
		public_pct: args.public_pct
		team_pct: args.team_pct
		treasury_pct: args.treasury_pct
		investor_pct: args.investor_pct
		currency: args.currency
		price_sheet: price_sheet
		token_sheet: token_sheet
		investment_sheet: investment_sheet
		vesting_sheet: unsafe { nil }
	}
	
	simulations[name] = sim
	return sim
}

pub fn simulation_get(name string) !&Simulation {
	name_fixed := texttools.name_fix(name)
	return simulations[name_fixed] or {
		return error('Simulation "${name_fixed}" not found')
	}
}