module spreadsheet

import incubaid.herolib.data.markdown.elements
import incubaid.herolib.ui.console

pub fn (s Sheet) wiki_title_chart(args RowGetArgs) !string {
	return s.title_chart(args).markdown()
}

pub fn (s_ Sheet) wiki_row_overview(args RowGetArgs) !string {
	s := s_.filter(args)!

	rows_values := s.rows.values().map([it.name, it.description, it.tags])
	mut rows := []elements.Row{}
	for values in rows_values {
		rows << elements.Row{
			cells: values.map(&elements.Paragraph{
				content: it
			})
		}
	}
	header_items := ['Row Name', 'Description', 'Tags']
	table := elements.Table{
		header: header_items.map(&elements.Paragraph{
			content: it
		})
		// TODO: need to use the build in mechanism to filter rows
		rows:       rows
		alignments: [.left, .left, .left]
	}
	return table.markdown()
}

// produce a nice looking bar chart see
// https://echarts.apache.org/examples/en/editor.html?c=line-stack
pub fn (s Sheet) wiki_line_chart(args_ RowGetArgs) !string {
	return s.line_chart(args_)!.markdown()
}

// produce a nice looking bar chart see
// https://echarts.apache.org/examples/en/index.html#chart-type-bar
pub fn (s Sheet) wiki_bar_chart(args_ RowGetArgs) !string {
	return s.bar_chart(args_)!.markdown()
}

// produce a nice looking bar chart see
// https://echarts.apache.org/examples/en/index.html#chart-type-bar
pub fn (s Sheet) wiki_pie_chart(args_ RowGetArgs) !string {
	return s.pie_chart(args_)!.markdown()
}
