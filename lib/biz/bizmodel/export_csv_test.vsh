#!/usr/bin/env -S v -n -w -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import freeflowuniverse.herolib.biz.bizmodel

bizmodel_name := 'test'
export_path := '${os.home_dir}/Downloads/bizmodel'
plbook_path := os.dir(@FILE) + '/exampledata'

mut model := bizmodel.generate(bizmodel_name, plbook_path)!

// Export to CSV
model.export_csv(
	path:          export_path
	include_empty: false
	separator:     '|'
)!

// // Verify files were created
// employees_path := os.join_path(export_path, 'employees.csv')
// products_path := os.join_path(export_path, 'products.csv')
// departments_path := os.join_path(export_path, 'departments.csv')

// assert os.exists(employees_path), 'employees.csv should exist'
// assert os.exists(products_path), 'products.csv should exist'
// assert os.exists(departments_path), 'departments.csv should exist'

// // Read and verify content
// employees_content := os.read_file(employees_path)!
// assert employees_content.contains('Name|Role|Department|Cost|Start Date'), 'employees.csv should have correct header'

// products_content := os.read_file(products_path)!
// assert products_content.contains('Name|Description|Price|Cost'), 'products.csv should have correct header'

// departments_content := os.read_file(departments_path)!
// assert departments_content.contains('Name|Description|Budget'), 'departments.csv should have correct header'
