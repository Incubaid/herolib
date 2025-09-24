module bizmodel

import arrays
import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.ui.console

// revenue_total calculates and aggregates the total revenue and cost of goods sold (COGS) for the business model
fn (mut sim BizModel) pl_total() ! {
	mut sheet := sim.sheet

	// sheet.pprint(nr_columns: 10)!

	mut pl_total := sheet.group2row(
		name:    'pl_summary'
		include: ['pl']
		tags:    'summary'
		descr:   'Cashflow Summary'
	)!

	// sheet.pprint(nr_columns: 10)!

	// println(pl_total)

	// if true{panic("sdsd")}
}
