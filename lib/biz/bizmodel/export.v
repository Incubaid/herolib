module bizmodel

import os
// import freeflowuniverse.herolib.web.docusaurus
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core.pathlib

@[params]
pub struct ExportArgs {
pub mut:
	name        string
	title       string
	description string
	path        string
}

pub fn (b BizModel) export(args ExportArgs) ! {
	name := if args.name != '' { args.name } else { texttools.snake_case(args.title) }
	path := pathlib.get_dir(
		path:   os.join_path(os.home_dir(), '/hero/var/bizmodel/exports/${name}')
		create: true
		empty:  true
	)!

	b.write_introduction(args)!
	b.write_operational_plan(args)!
	b.write_revenue_model(args)!
	// b.write_cost_structure(args)!
	// b.export_summary()
	// b.export_business_description()
	// b.export_market_analysis()
	// b.export_business_model()
	// b.export_revenue_model(export)!
	// b.export_cost_structure(export)
	// b.export_operational_plan(export)!
	// b.export_fundraising(export)
}

pub fn (model BizModel) write_introduction(args ExportArgs) ! {
	mut index_page := pathlib.get_file(path: '${args.path}/introduction.md')!
	// mut tmpl_index := $tmpl('templates/index.md')
	index_page.template_write($tmpl('templates/introduction.md'), true)!
}

pub fn (model BizModel) write_operational_plan(args ExportArgs) ! {
	mut sim:=model
	mut dir := pathlib.get_dir(path: '${args.path}/operational_plan')!
	mut ops_page := pathlib.get_file(path: '${dir.path}/operational_plan.md')!
	ops_page.write('# Operational Plan')!

	mut hr_dir := pathlib.get_dir(path: '${dir.path}/human_resources')!
	mut hr_page := pathlib.get_file(path: '${hr_dir.path}/human_resources.md')!
	hr_page.template_write($tmpl('./templates/human_resources.md'), true)!

	for key, employee in model.employees {
		mut employee_page := pathlib.get_file(
			path: '${hr_dir.path}/${texttools.snake_case(employee.name)}.md'
		)!
		employee_cost_chart := model.sheet.line_chart(
			rowname: 'hr_cost_${employee.name}'
			unit:    .million
		)!.mdx()
		employee_page.template_write($tmpl('./templates/employee.md'), true)!
	}

	mut depts_dir := pathlib.get_dir(path: '${dir.path}/departments')!

	mut employee_names := map[string]string{}
	for _, empl in sim.employees {
		employee_names[empl.name] = empl.name
		if empl.page.len > 0 {
			employee_names[empl.name] = '[${empl.name}](${empl.page})'
		}
	}

	for key, department in model.departments {
		dept := department
		mut dept_page := pathlib.get_file(
			path: '${depts_dir.path}/${texttools.snake_case(department.name)}.md'
		)!
		// dept_cost_chart := model.sheet.line_chart(rowname:'hr_cost_${employee.name}', unit: .million)!.mdx()
		// println(employee_cost_chart)
		dept_page.template_write($tmpl('./templates/department.md'), true)!
	}
}

pub fn (model BizModel) write_revenue_model(args ExportArgs) ! {
	mut dir := pathlib.get_dir(path: '${args.path}/revenue_model')!
	mut rm_page := pathlib.get_file(path: '${dir.path}/revenue_model.md')!
	rm_page.write('# Revenue Model')!

	mut products_dir := pathlib.get_dir(path: '${dir.path}/products')!
	mut products_page := pathlib.get_file(path: '${products_dir.path}/products.md')!
	products_page.template_write('# Products', true)!

	name1 := 'example'
	for key, product in model.products {
		mut product_page := pathlib.get_file(
			path: '${products_dir.path}/${texttools.snake_case(product.name)}.md'
		)!
		product_page.template_write($tmpl('./templates/product.md'), true)!
	}
}

pub fn (model BizModel) write_cost_structure(args ExportArgs) ! {
	mut dir := pathlib.get_dir(path: '${args.path}/cost_structure')!
	mut cs_page := pathlib.get_file(path: '${dir.path}/cost_structure.md')!
	cs_page.write('# Cost Structure')!
}
