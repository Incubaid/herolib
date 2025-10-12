module spreadsheet

import incubaid.herolib.data.markdown.elements
import incubaid.herolib.ui.console
import incubaid.herolib.web.echarts

pub fn (s Sheet) title_chart(args RowGetArgs) echarts.EChartsOption {
	return echarts.EChartsOption{
		title: echarts.Title{
			text:    args.title
			subtext: args.title_sub
			left:    'center'
		}
	}
}

pub fn (s Sheet) line_chart(args_ RowGetArgs) !echarts.EChartsOption {
	mut args := args_

	rownames := s.rownames_get(args)!
	header := s.header_get_as_string(args.period_type)!
	mut series := []echarts.Series{}

	for rowname in rownames {
		data := s.data_get_as_string(RowGetArgs{
			...args
			rowname: rowname
		})!
		series << echarts.Series{
			name:  rowname
			type_: 'line'
			stack: 'Total'
			data:  data.split(',')
		}
	}

	return echarts.EChartsOption{
		title:   s.title_chart(args).title
		tooltip: echarts.Tooltip{
			trigger: 'axis'
		}
		legend:  echarts.Legend{
			data: rownames
		}
		grid:    echarts.Grid{
			left:          '3%'
			right:         '4%'
			bottom:        '3%'
			contain_label: true
		}
		toolbox: echarts.Toolbox{
			feature: echarts.ToolboxFeature{
				save_as_image: {}
			}
		}
		x_axis:  echarts.XAxis{
			type_:        'category'
			boundary_gap: false
			data:         header.split(',')
		}
		y_axis:  echarts.YAxis{
			type_: 'value'
		}
		series:  series
	}
}

pub fn (s Sheet) bar_chart(args_ RowGetArgs) !echarts.EChartsOption {
	mut args := args_
	args.rowname = s.rowname_get(args)!
	header := s.header_get_as_list(args.period_type)!
	data := s.data_get_as_list(args)!

	return echarts.EChartsOption{
		title:  s.title_chart(args).title
		x_axis: echarts.XAxis{
			type_: 'category'
			data:  header
		}
		y_axis: echarts.YAxis{
			type_: 'value'
		}
		series: [
			echarts.Series{
				name:  args.rowname
				type_: 'bar'
				data:  data
				stack: ''
			},
		]
	}
}

pub fn (s Sheet) pie_chart(args_ RowGetArgs) !echarts.EChartsOption {
	mut args := args_
	args.rowname = s.rowname_get(args)!
	header := s.header_get_as_list(args.period_type)!
	data := s.data_get_as_list(args)!

	if header.len != data.len {
		return error('Data and header lengths must match.')
	}

	mut pie_data := []map[string]string{}
	for i, _ in data {
		pie_data << {
			'value': data[i].trim_space().trim("'")
			'name':  header[i].trim_space().trim("'")
		}
	}

	return echarts.EChartsOption{
		title:   s.title_chart(args).title
		tooltip: echarts.Tooltip{
			trigger: 'item'
		}
		legend:  echarts.Legend{
			data:   header
			orient: 'vertical'
			left:   'left'
		}
		series:  [
			echarts.Series{
				name:     'Data'
				type_:    'pie'
				radius:   args.size.int()
				data:     pie_data.map(it.str())
				emphasis: echarts.Emphasis{
					item_style: echarts.ItemStyle{
						shadow_blur:     10
						shadow_offset_x: 0
						shadow_color:    'rgba(0, 0, 0, 0.5)'
					}
				}
			},
		]
	}
}
