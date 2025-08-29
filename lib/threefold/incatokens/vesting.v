module incatokens

import freeflowuniverse.herolib.biz.spreadsheet

// Create vesting schedule in spreadsheet
pub fn (mut sim Simulation) create_vesting_schedules() ! {
	// Create vesting sheet
	mut vesting_sheet := spreadsheet.sheet_new(
		name:  '${sim.name}_vesting'
		nrcol: 60 // 60 months
		curr:  sim.params.simulation.currency
	)!

	// Team vesting
	team_tokens := sim.params.distribution.total_supply * sim.params.distribution.team_pct
	mut team_row := vesting_sheet.row_new(
		name:  'team_vesting'
		tags:  'category:team type:vesting'
		descr: 'Team token vesting schedule'
	)!
	sim.apply_vesting_schedule(mut team_row, team_tokens, sim.team_vesting)!

	// Treasury vesting
	treasury_tokens := sim.params.distribution.total_supply * sim.params.distribution.treasury_pct
	mut treasury_row := vesting_sheet.row_new(
		name:  'treasury_vesting'
		tags:  'category:treasury type:vesting'
		descr: 'Treasury token vesting schedule'
	)!
	sim.apply_vesting_schedule(mut treasury_row, treasury_tokens, sim.treasury_vesting)!

	// Investor rounds vesting
	for round in sim.investor_rounds {
		round_tokens := sim.params.distribution.total_supply * round.allocation_pct
		mut round_row := vesting_sheet.row_new(
			name:  '${round.name}_vesting'
			tags:  'category:investor round:${round.name} type:vesting'
			descr: '${round.name} investor vesting schedule'
		)!
		sim.apply_vesting_schedule(mut round_row, round_tokens, round.vesting)!
	}

	// Create total unlocked row
	mut total_row := vesting_sheet.group2row(
		name:          'total_unlocked'
		include:       ['type:vesting']
		tags:          'summary type:total_vesting'
		descr:         'Total tokens unlocked over time'
		aggregatetype: .sum
	)!

	sim.vesting_sheet = vesting_sheet
}

fn (sim Simulation) apply_vesting_schedule(mut row spreadsheet.Row, total_tokens f64, schedule VestingSchedule) ! {
	initial_unlocked_tokens := total_tokens * schedule.initial_unlock_pct
	remaining_tokens_to_vest := total_tokens - initial_unlocked_tokens

	monthly_vesting_amount := if schedule.vesting_months > 0 {
		remaining_tokens_to_vest / f64(schedule.vesting_months)
	} else {
		0.0
	}

	for month in 0 .. row.sheet.nrcol {
		if month == 0 {
			// Initial unlock at month 0
			row.cells[month].val = initial_unlocked_tokens
		} else if month < schedule.cliff_months {
			// Before cliff, only initial unlock is available
			row.cells[month].val = initial_unlocked_tokens
		} else if month < schedule.cliff_months + schedule.vesting_months {
			// During vesting period (after cliff)
			months_after_cliff := month - schedule.cliff_months + 1
			row.cells[month].val = initial_unlocked_tokens +
				(monthly_vesting_amount * f64(months_after_cliff))
		} else {
			// After vesting complete
			row.cells[month].val = total_tokens
		}
	}
}
