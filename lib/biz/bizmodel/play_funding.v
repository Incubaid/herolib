module bizmodel

import incubaid.herolib.core.playbook { Action }

// !!hr.funding_define
// - name: identifier for the funding entity
// - descr: human-readable description
// - investment: format month\:amount, e.g. 0:10000,12:5000
// - type: 'loan' or 'capital'
fn (mut m BizModel) funding_define_action(action Action) !Action {
	mut name := action.params.get('name') or {
		return error('funding "name" is required for action `${action.name}`\n${action}')
	}

	mut descr := action.params.get_default('descr', '')!
	if descr.len == 0 {
		descr = action.params.get_default('description', '')!
	}

	mut investment := action.params.get_default('investment', '')!
	if investment.len == 0 {
		return error('investment is required (format: "0:10000,6:20000") for funding `${name}`')
	}

	mut fundingtype := action.params.get_default('type', 'capital')!.to_lower()
	if fundingtype !in ['loan', 'capital'] {
		return error('Invalid funding "type": "${fundingtype}". Allowed: "loan", "capital"')
	}

	m.sheet.row_new(
		name:        'funding_${name}'
		growth:      investment
		tags:        'funding type:${fundingtype}'
		descr:       descr
		extrapolate: action.params.get_default_false('extrapolate')
	)!

	return action
}

fn (mut sim BizModel) funding_total() ! {
	sim.sheet.group2row(
		name:    'funding_total'
		include: ['funding']
		tags:    'pl'
		descr:   'Funding Total'
	)!
}
