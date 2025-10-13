module spreadsheet

import os
import incubaid.herolib.core.pathlib

@[params]
pub struct ExportArgs {
pub mut:
	path string
}

fn format_number(val f64) string {
	if val < 0.001 && val > -0.001 {
		return '0'
	}
	if val >= 1000.0 || val <= -1000.0 {
		return int(val).str()
	}
	// Format small numbers with 3 decimal places to handle floating point precision
	return '${val:.3f}'
}

pub fn (mut s Sheet) export(args ExportArgs) !string {
	mut result := []string{}

	// Add headers
	mut header_row := ['Name', 'Description', 'AggregateType', 'Tags', 'Subgroup']
	header_row << s.header()!
	result << header_row.join('|')

	// Add rows
	for _, row in s.rows {
		mut row_data := [row.name, row.description, row.aggregatetype.str(), row.tags, row.subgroup]
		for cell in row.cells {
			if cell.empty {
				row_data << '-'
			} else {
				row_data << format_number(cell.val)
			}
		}
		result << row_data.join('|')
	}

	if args.path.len > 0 {
		mut p := pathlib.get_file(
			path:   args.path.replace('~', os.home_dir())
			create: true
			delete: true
		)!
		p.write(result.join('\n'))!
	}

	return result.join('\n')
}
