module bizmodel

import incubaid.herolib.core.playbook

// revenue_total calculates and aggregates the total revenue and cost of goods sold (COGS) for the business model
fn (mut sim BizModel) revenue_total() ! {
	mut sheet := sim.sheet

	_ := sheet.group2row(
		name:    'revenue_total'
		include: ['rev']
		tags:    'total revtotal pl'
		descr:   'Revenue Total'
	)!
	    _ := sheet.group2row(
		name:    'cogs_total'
		include: ['cogs']
		tags:    'total cogstotal pl'
		descr:   'Cost of Goods Total.'
	)!
	_ := sheet.group2row(
		name:    'margin_total'
		include: ['margin']
		tags:    'total margintotal'
		descr:   'total margin.'
	)!

	// println(revenue_total)
	// println(cogs_total)
	// println(margin_total)
}
