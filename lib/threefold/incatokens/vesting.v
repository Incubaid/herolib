module incatokens

import freeflowuniverse.herolib.biz.spreadsheet

// Create vesting schedule in spreadsheet
pub fn (mut sim Simulation) create_vesting_schedules() ! {
	// Create vesting sheet
	mut vesting_sheet := spreadsheet.sheet_new(
		name: '${sim.name}_vesting'
		nrcol: 60 // 60 months
		curr: sim.currency
	)!
	
	// Team vesting
	team_tokens := sim.total_supply * sim.team_pct
	mut team_row := vesting_sheet.row_new(
		name: 'team_vesting'
		tags: 'category:team type:vesting'
		descr: 'Team token vesting schedule'
	)!
	sim.apply_vesting_schedule(mut team_row, team_tokens, sim.team_vesting)!
	
	// Treasury vesting
	treasury_tokens := sim.total_supply * sim.treasury_pct
	mut treasury_row := vesting_sheet.row_new(
		name: 'treasury_vesting'
		tags: 'category:treasury type:vesting'
		descr: 'Treasury token vesting schedule'
	)!
	sim.apply_vesting_schedule(mut treasury_row, treasury_tokens, sim.treasury_vesting)!
	
	// Investor rounds vesting
	for round in sim.investor_rounds {
		round_tokens := sim.total_supply * round.allocation_pct
		mut round_row := vesting_sheet.row_new(
			name: '${round.name}_vesting'
			tags: 'category:investor round:${round.name} type:vesting'
			descr: '${round.name} investor vesting schedule'
		)!
		sim.apply_vesting_schedule(mut round_row, round_tokens, round.vesting)!
	}
	
	// Create total unlocked row
	mut total_row := vesting_sheet.group2row(
		name: 'total_unlocked'
		include: ['type:vesting']
		tags: 'summary type:total_vesting'
		descr: 'Total tokens unlocked over time'
		aggregatetype: .sum
	)!
	
	sim.vesting_sheet = vesting_sheet
}

fn (sim Simulation) apply_vesting_schedule(mut row spreadsheet.Row, total_tokens f64, schedule VestingSchedule) ! {
	monthly_unlock := total_tokens / f64(schedule.vesting_months)
	
	for month in 0 .. row.sheet.nrcol {
		if month < schedule.cliff_months {
			// Before cliff, no tokens unlocked
			row.cells[month].val = 0
		} else if month < schedule.cliff_months + schedule.vesting_months {
			// During vesting period
			months_vested := month - schedule.cliff_months + 1
			row.cells[month].val = monthly_unlock * f64(months_vested)
		} else {
			// After vesting complete
			row.cells[month].val = total_tokens
		}
	}
}