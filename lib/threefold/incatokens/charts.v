module incatokens

import incubaid.herolib.biz.spreadsheet
import incubaid.herolib.web.echarts

// Generate price evolution chart
pub fn (sim Simulation) generate_price_chart() !echarts.EChartsOption {
	mut rownames := []string{}
	for name, _ in sim.scenarios {
		rownames << 'scenario_${name}_price'
	}

	return sim.price_sheet.line_chart(
		rowname:     rownames.join(',')
		period_type: .month
		title:       'INCA Token Price Evolution'
		title_sub:   'Price paths across different scenarios'
		unit:        .normal
	)!
}

// Generate market cap chart
pub fn (sim Simulation) generate_market_cap_chart() !echarts.EChartsOption {
	// Create market cap rows from price rows
	mut mc_sheet := spreadsheet.sheet_new(
		name:  '${sim.name}_market_cap'
		nrcol: sim.price_sheet.nrcol
		curr:  sim.params.simulation.currency
	)!

	for name, scenario in sim.scenarios {
		mut mc_row := mc_sheet.row_new(
			name:  'scenario_${name}_mc'
			tags:  'scenario:${name} type:market_cap'
			descr: 'Market cap for ${name} scenario'
		)!

		price_row := sim.price_sheet.row_get('scenario_${name}_price')!
		for i, cell in price_row.cells {
			mc_row.cells[i].val = cell.val * sim.params.distribution.total_supply
		}
	}

	return mc_sheet.bar_chart(
		namefilter:  mc_sheet.rows.keys()
		period_type: .quarter
		title:       'INCA Market Capitalization'
		title_sub:   'Market cap evolution by quarter'
		unit:        .million
	)!
}

// Generate vesting schedule chart
pub fn (mut sim Simulation) generate_vesting_chart() !echarts.EChartsOption {
	if isnil(sim.vesting_sheet) {
		sim.create_vesting_schedules()!
	}

	return sim.vesting_sheet.line_chart(
		includefilter: ['type:vesting']
		excludefilter: ['type:total_vesting']
		period_type:   .quarter
		title:         'Token Vesting Schedule'
		title_sub:     'Cumulative tokens unlocked over time'
		unit:          .million
	)!
}
