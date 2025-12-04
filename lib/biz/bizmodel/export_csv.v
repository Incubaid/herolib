module bizmodel

import os
import incubaid.herolib.core.pathlib

@[params]
pub struct ExportCSVArgs {
pub mut:
	path          string
	    include_empty bool // whether to include empty cells or not
	separator     string = '|'   // separator character for CSV
}

// export_csv exports the business model data to CSV files
pub fn (model BizModel) export_csv(args ExportCSVArgs) ! {
	mut path := args.path
	if path == '' {
		path = os.join_path(os.home_dir(), 'hero/var/bizmodel/exports')
	}
	mut dir := pathlib.get_dir(path: path, create: true)!

	// Export employees data
	mut employees_data := []string{}
	header := ['Name', 'Role', 'Department', 'Cost', 'Start Date'].map(fn [args] (s string) string {
		return format_csv_value(s, args.separator)
	}).join(args.separator)
	employees_data << header

	for _, employee in model.employees {
		row := [
			employee.name,
			employee.role,
			employee.department,
			employee.cost.str(),
			if start_date := employee.start_date { start_date.str() } else { '' },
		].map(fn [args] (s string) string {
			return format_csv_value(s, args.separator)
		}).join(args.separator)
		employees_data << row
	}
	mut emp_file := pathlib.get_file(
		path:   os.join_path(dir.path, 'employees.csv')
		create: true
		delete: true
	)!
	emp_file.write(employees_data.join('\n'))!

	// Export products data
	mut products_data := []string{}
	products_header := ['Name', 'Description'].map(fn [args] (s string) string {
		return format_csv_value(s, args.separator)
	}).join(args.separator)
	products_data << products_header

	for _, product in model.products {
		row := [
			product.name,
			product.description,
		].map(fn [args] (s string) string {
			return format_csv_value(s, args.separator)
		}).join(args.separator)
		products_data << row
	}
	mut prod_file := pathlib.get_file(
		path:   os.join_path(dir.path, 'products.csv')
		create: true
		delete: true
	)!
	prod_file.write(products_data.join('\n'))!

	// Export departments data
	mut departments_data := []string{}
	departments_header := ['Name', 'Description'].map(fn [args] (s string) string {
		return format_csv_value(s, args.separator)
	}).join(args.separator)
	departments_data << departments_header

	for _, department in model.departments {
		row := [
			department.name,
			department.description,
		].map(fn [args] (s string) string {
			return format_csv_value(s, args.separator)
		}).join(args.separator)
		departments_data << row
	}
	mut dept_file := pathlib.get_file(
		path:   os.join_path(dir.path, 'departments.csv')
		create: true
		delete: true
	)!
	dept_file.write(departments_data.join('\n'))!
}

// format_csv_value formats a value for CSV export, handling special characters
fn format_csv_value(val string, separator string) string {
	// If value contains the separator, quotes, or newlines, wrap in quotes and escape quotes
	if val.contains(separator) || val.contains('"') || val.contains('\n') {
		return '"${val.replace('"', '""')}"'
	}
	return val
}
