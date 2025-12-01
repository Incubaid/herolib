module spreadsheet

import os
import math
import strconv

// pad_right pads a string on the right with spaces to a specified length
fn pad_right(s string, length int) string {
	if s.len >= length {
		return s
	}
	mut res := s
	for _ in 0 .. length - s.len {
		res += ' '
	}
	return res
}

@[params]
pub struct PPrintArgs {
pub mut:
	group_months int = 1 // e.g. if 2 then will group by 2 months
	nr_columns   int // number of columns to show in the table, 0 is all
	description  bool // show description in the table
	aggrtype     bool = true // show aggregate type in the table
	tags         bool = true // show tags in the table
	subgroup     bool // show subgroup in the table
}

// calculate_column_widths calculates the maximum width for each column
fn calculate_column_widths(rows [][]string) []int {
	if rows.len == 0 {
		return []int{}
	}
	mut max_nr_cols := 0
	for row in rows {
		if row.len > max_nr_cols {
			max_nr_cols = row.len
		}
	}

	mut widths := []int{len: max_nr_cols, init: 0}
	for _, row in rows {
		for i, cell in row {
			if cell.len > widths[i] {
				widths[i] = cell.len
			}
		}
	}
	return widths
}

// format_row formats a single row with padding based on column widths
fn format_row(row []string, widths []int) string {
	mut formatted_cells := []string{}
	for i, cell in row {
		formatted_cells << pad_right(cell, widths[i])
	}
	return formatted_cells.join(' ')
}

pub fn (mut s Sheet) pprint(args PPrintArgs) ! {
	mut all_rows := [][]string{}

	// Prepare header row
	mut header_row := ['Name']
	if args.description {
		header_row << 'Description'
	}
	if args.aggrtype {
		header_row << 'AggregateType'
	}
	if args.tags {
		header_row << 'Tags'
	}
	if args.subgroup {
		header_row << 'Subgroup'
	}

	header_row << s.header()!
	all_rows << header_row

	// Prepare data rows
	for _, row in s.rows {
		// println('Processing row: ${row.name}')
		mut row_data := []string{} // Initialize row_data for each row
		row_data << row.name // Add the name of the row
		if args.description {
			row_data << row.description
		}
		if args.aggrtype {
			row_data << row.aggregatetype.str()
		}
		if args.tags {
			row_data << row.tags
		}
		if args.subgroup {
			row_data << row.subgroup
		}

		for cell in row.cells {
			if cell.empty {
				row_data << '-'
			} else {
				row_data << float_repr(cell.val, row.reprtype)
			}
		}
		mut is_empty_row := true
		mut data_start_index := 1 // for row.name
		if args.description {
			data_start_index++
		}
		if args.aggrtype {
			data_start_index++
		}
		if args.tags {
			data_start_index++
		}
		if args.subgroup {
			data_start_index++
		}

		// check if row is empty
		// println(row_data)
		for i := data_start_index; i < row_data.len; i++ {
			cell_val := row_data[i]
			if cell_val.trim_space() != '' && cell_val.trim_space() != '-' {
				// println("Row '${row.name}' has non-empty cell at index $i: '$cell_val'")
				is_empty_row = false
				break
			}
		}
		if !is_empty_row {
			all_rows << row_data
		}
	}

	if args.nr_columns > 0 {
		mut data_start_index := 1 // for row.name
		if args.description {
			data_start_index++
		}
		if args.aggrtype {
			data_start_index++
		}
		if args.tags {
			data_start_index++
		}
		if args.subgroup {
			data_start_index++
		}
		max_cols := data_start_index + args.nr_columns
		mut new_all_rows := [][]string{}
		for _, row in all_rows {
			if row.len > max_cols {
				new_all_rows << row[0..max_cols]
			} else {
				new_all_rows << row
			}
		}
		all_rows = new_all_rows.clone()
	}

	// Calculate column widths
	widths := calculate_column_widths(all_rows)

	// Format all rows
	mut formatted_result := []string{}
	for _, row in all_rows {
		formatted_result << '| ' + format_row(row, widths) + ' |'
	}

	println(formatted_result.join('\n'))
}
