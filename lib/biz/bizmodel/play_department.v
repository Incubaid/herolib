module bizmodel

import incubaid.herolib.core.playbook { Action }

// !!bizmodel.department_define bizname:'test'
//     name:'engineering'
//     descr:'Software Development Department'
//     title:'Engineering Division'
//     avg_monthly_cost:'6000USD' avg_indexation:'5%'
fn (mut m BizModel) department_define_action(action Action) !Action {
	bizname := action.params.get_default('bizname', '')!
	mut name := action.params.get('name') or { return error('department name is required') }
	mut descr := action.params.get_default('descr', '')!
	if descr.len == 0 {
		descr = action.params.get_default('description', '')!
	}

	department := Department{
		name:             name
		description:      descr
		title:            action.params.get_default('title', '')!
		page:             action.params.get_default('page', '')!
		avg_monthly_cost: action.params.get_default('avg_monthly_cost', '6000USD')!
		avg_indexation:   action.params.get_default('avg_indexation', '2%')!
	}
	m.departments[name] = &department
	return action
}
