module bizmodel

import freeflowuniverse.herolib.core.playbook { Action }
import freeflowuniverse.herolib.data.currency
import math

// Example HeroScript for cost_define_action:
// !!bizmodel.cost_define bizname:'test'
//     name:'office_rent'
//     descr:'Office Rent'
//     cost:'5000USD'
//     indexation:'3%'
//     costcenter:'marketing_cc'
//     cost_percent_revenue:'1%'
fn (mut m BizModel) cost_define_action(action Action) !Action {
	mut name := action.params.get('name') or { return error('Cost name is required.') }
	mut descr := action.params.get_default('descr', '')!
	if descr.len == 0 {
		descr = action.params.get_default('description', '')!
	}
	mut cost := action.params.get_default('cost', '0.0')! // is extrapolated

	department := action.params.get_default('department', 'default')!
	if department != 'default' && department !in m.departments {
		return error('Department `${department}` not found. Please define it first.')
	}

	costcenter := action.params.get_default('costcenter', 'default_costcenter')!
	if costcenter != 'default_costcenter' && costcenter !in m.costcenters {
		return error('Costcenter `${costcenter}` not found. Please define it first.')
	}

	cost_percent_revenue := action.params.get_percentage_default('cost_percent_revenue',
		'0%')!

	indexation := action.params.get_percentage_default('indexation', '0%')!

	if indexation > 0 {
		if cost.contains(':') {
			return error('cannot specify cost growth and indexation, should be no : inside cost param.')
		}
		// Assuming 6 years for indexation, adjust as needed
		mut cost_amount := currency.amount_get(cost)!
		cost_amount_val_result := cost_amount.usd() * math.powf(1 + f32(indexation), 6)
		cost = '0:${cost_amount.usd()},59:${cost_amount_val_result}'
	}

	mut cost_row := m.sheet.row_new(
		name:        'cost_${name}'
		growth:      cost
		tags:        'department:${department} ocost'
		descr:       descr
		extrapolate: action.params.get_default_true('extrapolate')
	)!
	cost_row = cost_row.action(action: .reverse)!

	if cost_percent_revenue > 0 {
		// println(cost_row)
		mut revtotal := m.sheet.row_get('revenue_total')!

		for x in 0 .. cost_row.cells.len {
			mut curcost := -cost_row.cells[x].val
			mut currev := revtotal.cells[x].val
			// println("currev: ${currev}, curcost: ${curcost}, costpercent_revenue: ${currev*cost_percent_revenue}")
			if currev * cost_percent_revenue > curcost {
				cost_row.cells[x].val = -currev * cost_percent_revenue
			}
		}
		// println(cost_row)
	}
	return action
}

fn (mut sim BizModel) cost_total() ! {
	sim.sheet.group2row(
		name:    'cost_total'
		include: ['ocost']
		tags:    'pl'
		descr:   'Operational Costs Total.'
	)!
}
