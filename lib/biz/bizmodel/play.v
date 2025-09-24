module bizmodel

import arrays
import freeflowuniverse.herolib.core.playbook { Action, PlayBook }
import freeflowuniverse.herolib.ui.console

const action_priorities = {
	0: ['department_define', 'costcenter_define']
	1: ['revenue_define', 'funding_define']
	2: ['cost_define', 'employee_define']
	3: ['sheet_wiki', 'graph_bar_row', 'graph_pie_row', 'graph_line_row', 'row_overview']
}

pub fn play(mut plbook PlayBook) ! {
	if plbook.exists(filter: 'bizmodel.') == false {
		return
	}
	// group actions by which bizmodel they belong to
	actions_by_biz := arrays.group_by[string, &Action](plbook.find(filter: 'bizmodel.*')!,
		fn (a &Action) string {
		return a.params.get('bizname') or { 'default' }
	})

	// play actions for each biz in plbook
	for biz, actions in actions_by_biz {
		mut model := getset(biz)!
		model.play(mut plbook)!
	}
}

pub fn (mut m BizModel) play(mut plbook PlayBook) ! {
	mut actions := plbook.find(filter: 'bizmodel.*')!

	for action in actions.filter(it.name in action_priorities[0]) {
		m.act(*action)!
	}
	for action in actions.filter(it.name in action_priorities[1]) {
		m.act(*action)!
	}

	m.revenue_total()!

	for action in actions.filter(it.name in action_priorities[2]) {
		m.act(*action)!
	}

	m.hrcost_total()!
	m.funding_total()!
	m.cost_total()!
	m.pl_total()!

	// m.sheet.pprint(nr_columns: 10)!

	for action in actions.filter(it.name in action_priorities[3]) {
		m.act(*action)!
	}
}
