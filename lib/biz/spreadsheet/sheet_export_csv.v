module spreadsheet

import os
import incubaid.herolib.core.pathlib

@[params]
pub struct ExportCSVArgs {
pub mut:
	path          string
	include_empty bool   = false // whether to include empty cells or not
	separator     string = '|'   // separator character for CSV
}

// format_csv_value formats a value for CSV export, handling special characters
fn format_csv_value(val string, separator string) string {
	// If value contains the separator, quotes, or newlines, wrap in quotes and escape quotes
	if val.contains(separator) || val.contains('"') || val.contains('\n') {
		return '"${val.replace('"', '""')}"'
	}
	return val
}

// format_number_csv formats a number for CSV export
fn format_number_csv(val f64, include_empty bool) string {
	if val < 0.001 && val > -0.001 {
		if include_empty {
			return '0'
		}
		return ''
	}
	if val >= 1000.0 || val <= -1000.0 {
		return int(val).str()
	}
	// Format small numbers with up to 3 decimal places, removing trailing zeros
	str := '${val:.3f}'
	// Remove trailing zeros and decimal point if needed
	if str.contains('.') {
		str_trimmed := str.trim_right('0').trim_right('.')
		return str_trimmed
	}
	return str
}

// export_csv exports the sheet data to a CSV file with pipe separation
pub fn (mut s Sheet) export_csv(args ExportCSVArgs) !string {
	mut result := []string{}
	mut separator := args.separator

	// Add headers
	mut header_row := ['Name', 'Description', 'AggregateType', 'Tags', 'Subgroup']
	header_row << s.header()!
	result << header_row.map(format_csv_value(it, separator)).join(separator)

	// Add rows
	for _, row in s.rows {
		mut row_data := [
			format_csv_value(row.name, separator),
			format_csv_value(row.description, separator),
			format_csv_value(row.aggregatetype.str(), separator),
			format_csv_value(row.tags, separator),
			format_csv_value(row.subgroup, separator),
		]

		for cell in row.cells {
			if cell.empty && !args.include_empty {
				row_data << ''
			} else {
				val_str := format_number_csv(cell.val, args.include_empty)
				row_data << format_csv_value(val_str, separator)
			}
		}
		result << row_data.join(separator)
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
