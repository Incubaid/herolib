module bizmodel

import freeflowuniverse.herolib.core.playbook

// revenue_total calculates and aggregates the total revenue and cost of goods sold (COGS) for the business model
fn (mut sim BizModel) revenue_total() ! {
	mut sheet := sim.sheet

	mut revenue_total := sheet.group2row(
		name:    'revenue_total'
		include: ['rev']
		tags:    'total revtotal pl'
		descr:   'Revenue Total'
	)!
	mut cogs_total := sheet.group2row(
		name:    'cogs_total'
		include: ['cogs']
		tags:    'total cogstotal pl'
		descr:   'Cost of Goods Total.'
	)!
	mut margin_total := sheet.group2row(
		name:    'margin_total'
		include: ['margin']
		tags:    'total margintotal'
		descr:   'total margin.'
	)!

	// println(revenue_total)
	// println(cogs_total)
	// println(margin_total)
}
