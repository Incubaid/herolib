module bizmodel

import os
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.core.playbook { Action }
import freeflowuniverse.herolib.ui.console
// import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.data.paramsparser { Params }
import freeflowuniverse.herolib.biz.spreadsheet { PeriodType, RowGetArgs, UnitType }

pub fn (mut m BizModel) act(action Action) !Action {
	return match texttools.snake_case(action.name) {
		'funding_define' {
			m.funding_define_action(action)!
		}
		'revenue_define' {
			m.revenue_action(action)!
			m.revenue_item_action(action)!
		}
		'costcenter_define' {
			m.costcenter_define_action(action)!
		}
		'cost_define' {
			m.cost_define_action(action)!
		}
		'department_define' {
			m.department_define_action(action)!
		}
		'employee_define' {
			m.employee_define_action(action)!
		}
		'export_report' {
			m.new_report_action(action)!
		}
		'sheet_wiki' {
			m.export_sheet_action(action)!
		}
		'graph_bar_row' {
			m.export_graph_bar_action(action)!
		}
		'graph_pie_row' {
			m.export_graph_pie_action(action)!
		}
		'graph_line_row' {
			m.export_graph_line_action(action)!
		}
		'row_overview' {
			m.export_overview_action(action)!
		}
		else {
			return error('Unknown operation: ${action.name}')
		}
	}
}

fn (mut m BizModel) export_sheet_action(action Action) !Action {
	return m.export_action(m.sheet.wiki(row_args_from_params(action.params)!)!, action)
}

fn (mut m BizModel) export_graph_title_action(action Action) !Action {
	return m.export_action(m.sheet.wiki_title_chart(row_args_from_params(action.params)!)!,
		action)
}

fn (mut m BizModel) export_graph_line_action(action Action) !Action {
	return m.export_action(m.sheet.wiki_line_chart(row_args_from_params(action.params)!)!,
		action)
}

fn (mut m BizModel) export_graph_bar_action(action Action) !Action {
	return m.export_action(m.sheet.wiki_bar_chart(row_args_from_params(action.params)!)!,
		action)
}

pub fn (mut m BizModel) export_graph_pie_action(action Action) !Action {
	return m.export_action(m.sheet.wiki_pie_chart(row_args_from_params(action.params)!)!,
		action)
}

pub fn (mut m BizModel) export_overview_action(action Action) !Action {
	return m.export_action(m.sheet.wiki_row_overview(row_args_from_params(action.params)!)!,
		action)
}

fn (mut m BizModel) new_report_action(action Action) !Action {
	mut p := action.params
	path := p.get_default('path', '')!
	name := p.get_default('name', '')!
	title := p.get_default('title', '')!
	description := p.get_default('description', '')!
	m.export(path: path, name: name, title: title, description: description)!
	return action
}

// fetches args for getting row from params
pub fn row_args_from_params(p Params) !RowGetArgs {
	rowname := p.get_default('rowname', '')!
	namefilter := p.get_list_default('namefilter', [])!
	includefilter := p.get_list_default('includefilter', [])!
	excludefilter := p.get_list_default('excludefilter', [])!
	size := p.get_default('size', '')!
	title_sub := p.get_default('title_sub', '')!
	title := p.get_default('title', '')!
	unit := p.get_default('unit', 'normal')!
	unit_e := match unit {
		'thousand' { UnitType.thousand }
		'million' { UnitType.million }
		'billion' { UnitType.billion }
		else { UnitType.normal }
	}
	period_type := p.get_default('period_type', 'year')!
	if period_type !in ['year', 'month', 'quarter'] {
		return error('period type needs to be in year,month,quarter')
	}
	period_type_e := match period_type {
		'year' { PeriodType.year }
		'month' { PeriodType.month }
		'quarter' { PeriodType.quarter }
		else { PeriodType.error }
	}
	if period_type_e == .error {
		return error('period type needs to be in year,month,quarter')
	}

	rowname_show := p.get_default_true('rowname_show')
	descr_show := p.get_default_true('descr_show')

	return RowGetArgs{
		rowname:       rowname
		namefilter:    namefilter
		includefilter: includefilter
		excludefilter: excludefilter
		period_type:   period_type_e
		unit:          unit_e
		title_sub:     title_sub
		title:         title
		size:          size
		rowname_show:  rowname_show
		descr_show:    descr_show
	}
}

// creates the name for a file being exported given the params of the export action
fn (m BizModel) export_action(content string, action Action) !Action {
	// determine name of file being exported
	name := if action.params.exists('name') {
		action.params.get('name')!
	} else {
		if action.params.exists('title') {
			action.params.get('title')!
		} else {
			// if no name or title, name is ex: revenue_total_graph_bar_row
			rowname := action.params.get_default('rowname', '')!
			'${rowname}_${action.name}'
		}
	}

	// by default exports to working dir of bizmodel
	destination := action.params.get_default('destination', m.workdir)!

	mut path := pathlib.get_file(
		path:      os.join_path(destination, name)
		increment: true
		empty:     action.params.get_default_false('overwrite')
	)!

	path.write(content)!
	return action
}
