module bizmodel

import freeflowuniverse.herolib.core.playbook { Action }
import freeflowuniverse.herolib.core.texttools

// Example HeroScript for costcenter_define_action:
// !!bizmodel.costcenter_define bizname:'test'
//     name:'marketing_cc'
//     descr:'Marketing Cost Center'
//     department:'marketing'
fn (mut m BizModel) costcenter_define_action(action Action) !Action {
	mut name := action.params.get('name') or { return error('Costcenter name is required.') }
	mut descr := action.params.get_default('descr', '')!
	if descr.len == 0 {
		descr = action.params.get_default('description', '')!
	}

	mut department := action.params.get_default('department', 'default')!
	if department != 'default' && department !in m.departments {
		return error('Department `${department}` not found. Please define it first.')
	}
	mut cc := Costcenter{
		name:        name
		description: descr
		department:  department
	}
	m.costcenters[name] = &cc
	return action
}
