module bizmodel

import incubaid.herolib.core.texttools
import incubaid.herolib.core.playbook { Action }

pub struct RowDescrFields {
pub mut:
	name        string
	title       string
	description string
}

fn get_action_descr(action Action) !RowDescrFields {
	mut r := RowDescrFields{}

	r.name = action.params.get_default('name', '')!
	r.description = action.params.get_default('descr', '')!
	if r.description.len == 0 {
		r.description = action.params.get_default('description', '')!
	}
	if r.name.len == 0 {
		// make name ourselves
		r.name = texttools.name_fix(r.description)
	}

	r.name = texttools.name_fix(r.name)
	if r.name.len == 0 {
		return error('name and description is empty for ${action}')
	}
	r.name = r.name.replace('_', ' ').replace('-', ' ')
	r.description = r.description.replace('_', ' ').replace('-', ' ')

	return r
}
