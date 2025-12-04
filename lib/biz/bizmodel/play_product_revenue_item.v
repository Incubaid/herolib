module bizmodel

import incubaid.herolib.core.playbook { Action }
import incubaid.herolib.core.texttools

// see lib/biz/bizmodel/docs/revenue.md
fn (mut m BizModel) revenue_item_action(action Action) !Action {
	mut r := get_action_descr(action)!
	mut product := m.products[r.name] or { return error('Product "${r.name}" not found for revenue item action') }

	mut nr_sold := m.sheet.row_new(
		name:          '${r.name}_nr_sold'
		growth:        action.params.get_default('nr_sold', '0')!
		tags:          'name:${r.name}'
		descr:         'nr of items sold/month for ${r.name}'
		aggregatetype: .avg
		extrapolate:   true
	)!

	if nr_sold.max() > 0 {
		product.has_items = true
	} else {
		return action
	}

	mut revenue_item_setup_param := m.sheet.row_new(
		name:        '${r.name}_revenue_item_setup'
		growth:      action.params.get_default('revenue_item_setup', '0:0')!
		tags:        'name:${r.name}'
		descr:       'Item Revenue setup for ${r.name} Param'
		extrapolate: true
	)!

	mut revenue_item_monthly_param := m.sheet.row_new(
		name:        '${r.name}_revenue_item_monthly_param'
		growth:      action.params.get_default('revenue_item_monthly', '0:0')!
		tags:        'name:${r.name}'
		descr:       'Item Revenue monthly for ${r.name} Param'
		extrapolate: true
	)!

	mut revenue_item_monthly_perc_temp := revenue_item_setup_param.action(
		name:   '${r.name}_revenue_item_monthly_perc_temp'
		descr:  'Monthly sales as percentage from Setup Revenue for ${r.name}'
		action: .multiply
		val:    action.params.get_float_default('revenue_item_monthly_perc', 0.0)!
		tags:   'name:${r.name}'
	)!

	mut revenue_item_monthly := revenue_item_monthly_param.action(
		name:   '${r.name}_revenue_item_monthly'
		descr:  'Item Revenue monthly for ${r.name}'
		action: .add
		rows:   [revenue_item_monthly_perc_temp]
		tags:   'name:${r.name}'
	)!

	revenue_item_monthly_perc_temp.delete()

	mut cogs_item_setup_param := m.sheet.row_new(
		name:        '${r.name}_cogs_item_setup_param'
		growth:      action.params.get_default('cogs_item_setup', '0:0')!
		tags:        'name:${r.name}'
		descr:       'Item COGS setup for ${r.name} parameter'
		extrapolate: true
	)!

	mut cogs_item_monthly_param := m.sheet.row_new(
		name:        '${r.name}_cogs_item_monthly_param'
		growth:      action.params.get_default('cogs_item_monthly', '0:0')!
		tags:        'name:${r.name}'
		descr:       'Item COGS monthly for ${r.name} parameter'
		extrapolate: true
	)!

	mut cogs_item_setup_rev_perc_temp := revenue_item_setup_param.action(
		name:   '${r.name}_cogs_item_setup_rev_perc_temp'
		descr:  'Setup cogs as percentage from Setup for ${r.name}'
		action: .multiply
		val:    action.params.get_float_default('cogs_item_setup_rev_perc', 0.0)!
		tags:   'name:${r.name}'
	)!

	mut cogs_item_monthly_rev_perc_temp := revenue_item_monthly_param.action(
		name:   '${r.name}_cogs_item_monthly_rev_perc_temp'
		descr:  'Monthly cogs as percentage from Monthly for ${r.name}'
		action: .multiply
		val:    action.params.get_float_default('cogs_item_monthly_rev_perc', 0.0)!
		tags:   'name:${r.name}'
	)!

	mut cogs_item_setup1 := cogs_item_setup_param.action(
		name:   '${r.name}_cogs_item_setup1'
		descr:  'Item COGS setup for ${r.name}'
		action: .add
		rows:   [cogs_item_setup_rev_perc_temp]
		tags:   'name:${r.name}'
	)!

	mut cogs_item_monthly := cogs_item_monthly_param.action(
		name:   '${r.name}_cogs_item_monthly'
		descr:  'Item COGS monthly for ${r.name}'
		action: .add
		rows:   [cogs_item_monthly_rev_perc_temp]
		tags:   'name:${r.name}'
	)!

	cogs_item_setup_rev_perc_temp.delete()
	cogs_item_monthly_rev_perc_temp.delete()

	////////////////////////////////////////////////////////////////
	// CALCULATE THE TOTAL (multiply with nr sold)

	mut revenue_setup := revenue_item_setup_param.action(
		name:        '${r.name}_revenue_setup'
		descr:       'Setup sales for ${r.name} total'
		action:      .multiply
		rows:        [nr_sold]
		tags:        'name:${r.name} rev'
		delaymonths: action.params.get_int_default('revenue_item_setup_delay', 0)!
	)!

	mut revenue_monthly_total := revenue_item_monthly.action(
		name:        '${r.name}_revenue_monthly_total'
		descr:       'Monthly sales for ${r.name} total'
		action:      .multiply
		rows:        [nr_sold]
		tags:        'name:${r.name}'
		delaymonths: action.params.get_int_default('revenue_item_monthly_delay', 0)!
	)!

	mut cogs_setup := cogs_item_setup1.action(
		name:        '${r.name}_cogs_setup'
		descr:       'Setup COGS for ${r.name} total'
		action:      .multiply
		rows:        [nr_sold]
		tags:        'name:${r.name} cogs'
		delaymonths: action.params.get_int_default('cogs_item_delay', 0)!
	)!

	mut cogs_monthly_total := cogs_item_monthly.action(
		name:        '${r.name}_cogs_monthly_total'
		descr:       'Monthly COGS for ${r.name} total'
		action:      .multiply
		rows:        [nr_sold]
		tags:        'name:${r.name}'
		delaymonths: action.params.get_int_default('cogs_item_delay', 0)!
	)!

	// DEAL WITH RECURRING

	mut revenue_monthly_recurring := revenue_monthly_total.recurring(
		name:     '${r.name}_revenue_monthly'
		descr:    'Revenue monthly recurring for ${r.name}'
		nrmonths: product.nr_months_recurring
		tags:     'name:${r.name} rev'
	)!

	revenue_monthly_total.delete()

	mut cogs_monthly_recurring := cogs_monthly_total.recurring(
		name:     '${r.name}_cogs_monthly'
		descr:    'COGS monthly recurring for ${r.name}'
		nrmonths: product.nr_months_recurring
		tags:     'name:${r.name} cogs'
	)!

	cogs_monthly_total.delete()

	_ := nr_sold.recurring(
		name:          '${r.name}_nr_active'
		descr:         'Nr products active because of recurring for ${r.name}'
		nrmonths:      product.nr_months_recurring
		aggregatetype: .max
		delaymonths:   action.params.get_int_default('revenue_item_monthly_delay', 0)!
	)!

	// DEAL WITH MARGIN

	mut margin_setup := revenue_setup.action(
		name:   '${r.name}_margin_setup'
		descr:  'Setup margin for ${r.name}'
		action: .substract
		rows:   [cogs_setup]
		tags:   'name:${r.name}'
	)!

	mut margin_monthly := revenue_monthly_recurring.action(
		name:   '${r.name}_margin_monthly'
		descr:  'Monthly margin for ${r.name}'
		action: .substract
		rows:   [cogs_monthly_recurring]
		tags:   'name:${r.name}'
	)!

	_ := margin_setup.action(
		name:   '${r.name}_margin'
		descr:  'Margin for ${r.name}'
		action: .add
		rows:   [margin_monthly]
		tags:   'name:${r.name} margin'
	)!

	return action
}
