module incatokens

import incubaid.herolib.core.texttools
import incubaid.herolib.biz.spreadsheet

__global (
	simulations map[string]&Simulation
)

// Create simulation from parameters struct - MAIN ENTRY POINT
pub fn simulation_new(params SimulationParams) !&Simulation {
	name := texttools.name_fix(params.name)

	// Initialize spreadsheets for tracking
	price_sheet := spreadsheet.sheet_new(
		name:  '${name}_prices'
		nrcol: params.simulation.nrcol
		curr:  params.simulation.currency
	)!

	token_sheet := spreadsheet.sheet_new(
		name:  '${name}_tokens'
		nrcol: params.simulation.nrcol
		curr:  params.simulation.currency
	)!

	investment_sheet := spreadsheet.sheet_new(
		name:  '${name}_investments'
		nrcol: params.simulation.nrcol
		curr:  params.simulation.currency
	)!

	mut sim := &Simulation{
		name:             name
		params:           params
		price_sheet:      price_sheet
		token_sheet:      token_sheet
		investment_sheet: investment_sheet
		vesting_sheet:    unsafe { nil }
	}

	simulations[name] = sim
	return sim
}

pub fn simulation_get(name string) !&Simulation {
	name_fixed := texttools.name_fix(name)
	return simulations[name_fixed] or { return error('Simulation "${name_fixed}" not found') }
}
