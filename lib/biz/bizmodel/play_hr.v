module bizmodel

import freeflowuniverse.herolib.core.playbook { Action }
import freeflowuniverse.herolib.data.currency
import math

// populate the params for hr
// !!bizmodel.department_define bizname:'test'
//     descr:'Junior Engineer'
//     nrpeople:'1:5,60:30'
//	   cost:'4000USD'
//	   indexation:'5%'
//     department:'engineering'
//	   cost_percent_revenue e.g. 4%, will make sure the cost will be at least 4% of revenue
fn (mut m BizModel) employee_define_action(action Action) !Action {
	// bizname := action.params.get_default('bizname', '')!
	mut name := action.params.get('name') or {
		return error('employee name is required in ${action.name}, now \n${action}')
	}
	mut descr := action.params.get_default('descr', '')!
	if descr.len == 0 {
		descr = action.params.get('description')!
	}

	department := action.params.get_default('department', 'default')!
	mut department_obj := m.departments[department] or {
		return error('department `${department}` not found, please define it first.')
	}

	costperson_default := currency.amount_get(department_obj.avg_monthly_cost)!

	mut cost := action.params.get_default('cost', department_obj.avg_monthly_cost)!
	indexation := action.params.get_percentage_default('indexation', department_obj.avg_indexation)!

	page := action.params.get_default('page', '')!

	cost_percent_revenue := action.params.get_percentage_default('cost_percent_revenue',
		'0%')!
	nrpeople := action.params.get_default('nrpeople', '1')!
	cost_center := action.params.get_default('costcenter', '')!

	if indexation > 0 {
		if cost.contains(':') {
			return error('cannot specify cost growth and indexation, should be no : inside cost param.')
		}
		cost = '0:${cost},60:${cost.f32() * math.powf(1 + f32(indexation), 6)}'
	}

	mut costpeople_row := m.sheet.row_new(
		name:     'hr_cost_${name}'
		growth:   cost
		tags:     'department:${department} hrcost'
		descr:    '${descr} Cost'
		subgroup: 'HR cost per department.'
	)!

	costpeople_row = costpeople_row.action(action: .reverse)!

	// multiply with nr of people if any
	mut nrpeople_row := m.sheet.row_new(
		name:          'hr_nrpeople_${name}'
		growth:        nrpeople
		tags:          'hrnr'
		descr:         '${descr} Nr of People'
		aggregatetype: .avg
	)!
	costpeople_row = costpeople_row.action(action: .multiply, rows: [nrpeople_row])!

	// lets make sure nr of people filled in properly as well as cost
	if cost_percent_revenue > 0 {
		mut revtotal := m.sheet.row_get('revenue_total')!
		// println(revtotal)
		for x in 0 .. nrpeople_row.cells.len {
			mut curcost := -costpeople_row.cells[x].val
			mut curpeople := nrpeople_row.cells[x].val
			mut currev := revtotal.cells[x].val
			// println("currev: ${currev}, curcost: ${curcost}, curpeople: ${curpeople}, costpercent_revenue: ${cost_percent_revenue}")
			if currev * cost_percent_revenue > curcost {
				costpeople_row.cells[x].val = -currev * cost_percent_revenue
				nrpeople_row.cells[x].val = f64(currev * cost_percent_revenue / costperson_default.usd())
			}
		}
		// println(costpeople_row)
		// println(nrpeople_row)
	}
	employee := Employee{
		name:                 name
		description:          descr
		department:           department
		cost:                 cost
		cost_percent_revenue: cost_percent_revenue
		nrpeople:             nrpeople
		indexation:           indexation
		cost_center:          cost_center
		page:                 page
		fulltime_perc:        action.params.get_percentage_default('fulltime', '100%')!
	}

	if name != '' {
		m.employees[name] = &employee
	}
	return action
}

fn (mut sim BizModel) hrcost_total() ! {
	sim.sheet.group2row(
		name:    'hr_cost_total'
		include: ['hrcost']
		tags:    'pl'
		descr:   'Human Resources Costs Total'
	)!
}
