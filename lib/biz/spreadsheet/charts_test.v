module spreadsheet

import incubaid.herolib.data.markdown.elements
import incubaid.herolib.ui.console
import incubaid.herolib.web.echarts

fn test_title_chart() {
	mut s := sheet_new() or { panic(err) }
	mut nrnodes := s.row_new(
		name:   'nrnodes'
		growth: '5:100,55:1000'
		tags:   'cat:nodes color:yellow urgent'
	)!
	args := RowGetArgs{
		rowname:   'nrnodes'
		title:     'Main Title'
		title_sub: 'Subtitle'
	}
	title := s.title_chart(args).title
	assert title.text == 'Main Title'
	assert title.subtext == 'Subtitle'
	assert title.left == 'center'
}

fn test_line_chart() {
	mut s := sheet_new() or { panic(err) }
	mut nrnodes := s.row_new(
		name:   'nrnodes'
		growth: '5:100,55:1000'
		tags:   'cat:nodes color:yellow urgent'
	)!
	args := RowGetArgs{
		rowname:     'nrnodes'
		title:       'Line Chart'
		period_type: .month
	}
	option := s.line_chart(args) or { panic(err) }
	assert option.title.text == 'Line Chart'
	assert option.tooltip.trigger == 'axis'
	assert option.grid.contain_label == true
}

fn test_bar_chart() {
	mut s := sheet_new() or { panic(err) }
	mut nrnodes := s.row_new(
		name:   'nrnodes'
		growth: '5:100,55:1000'
		tags:   'cat:nodes color:yellow urgent'
	)!
	args := RowGetArgs{
		rowname:     'nrnodes'
		title:       'Bar Chart'
		period_type: .year
	}
	option := s.bar_chart(args) or { panic(err) }
	assert option.title.text == 'Bar Chart'
	assert option.x_axis.type_ == 'category'
	assert option.y_axis.type_ == 'value'
}

fn test_pie_chart() {
	mut s := sheet_new() or { panic(err) }
	mut nrnodes := s.row_new(
		name:   'nrnodes'
		growth: '5:100,55:1000'
		tags:   'cat:nodes color:yellow urgent'
	)!
	args := RowGetArgs{
		rowname:     'nrnodes'
		title:       'Pie Chart'
		period_type: .quarter
	}
	option := s.pie_chart(args) or { panic(err) }
	assert option.title.text == 'Pie Chart'
	assert option.tooltip.trigger == 'item'
	assert option.legend.data.len > 0
}
