module codegenerator

import incubaid.herolib.ui.console
import incubaid.herolib.core.codeparser
import incubaid.herolib.core.pathlib
import os

fn test_markdown_generation() {
	console.print_header('CodeGenerator Markdown Test')
	console.print_lf(1)

	// Setup: Use the same test data as codeparser
	test_dir := setup_test_directory()
	defer {
		os.rmdir_all(test_dir) or {}
	}

	// Create output directory
	output_dir := '/tmp/codegen_output'
	os.rmdir_all(output_dir) or {}
	os.mkdir_all(output_dir) or { panic('Failed to create output dir') }
	defer {
		os.rmdir_all(output_dir) or {}
	}

	// Create generator
	console.print_item('Creating CodeGenerator...')
	mut gen := new(
		parser_path: test_dir
		output_dir:  output_dir
		recursive:   true
	)!

	console.print_item('Parser found ${gen.parser.list_modules().len} modules')
	console.print_lf(1)

	// Test filename conversion
	console.print_header('Test 1: Filename Conversion')
	struct TestCase {
		module_name string
		expected    string
	}

	test_cases := [
		TestCase{
			module_name: 'incubaid.herolib.core.code'
			expected:    'code.md'
		},
		TestCase{
			module_name: 'testdata'
			expected:    'testdata.md'
		},
		TestCase{
			module_name: 'testdata.services'
			expected:    'services.md'
		},
	]

	for test_case in test_cases {
		result := gen.module_to_filename(test_case.module_name)
		assert result == test_case.expected, 'Expected ${test_case.expected}, got ${result}'
		console.print_item('  ✓ ${test_case.module_name} -> ${result}')
	}
	console.print_lf(1)

	// Test module documentation generation
	console.print_header('Test 2: Module Documentation Generation')

	// Get a testdata module
	modules := gen.parser.list_modules()
	testdata_modules := modules.filter(it.contains('testdata'))

	assert testdata_modules.len > 0, 'No testdata modules found'

	for mod_name in testdata_modules {
		console.print_item('Generating docs for: ${mod_name}')

		md := gen.module_to_markdown(mod_name)!

		// Validate markdown content
		assert md.len > 0, 'Generated markdown is empty'
		assert md.contains('# Module:'), 'Missing module header'

		// List basic structure checks
		structs := gen.parser.list_structs(mod_name)
		functions := gen.parser.list_functions(mod_name)
		consts := gen.parser.list_constants(mod_name)

		if structs.len > 0 {
			assert md.contains('## Structs'), 'Missing Structs section'
			console.print_item('  - Found ${structs.len} structs')
		}

		if functions.len > 0 {
			assert md.contains('## Functions'), 'Missing Functions section'
			console.print_item('  - Found ${functions.len} functions')
		}

		if consts.len > 0 {
			assert md.contains('## Constants'), 'Missing Constants section'
			console.print_item('  - Found ${consts.len} constants')
		}
	}
	console.print_lf(1)

	// Test file writing
	console.print_header('Test 3: Write Generated Files')

	for mod_name in testdata_modules {
		gen.generate_module(mod_name)!
	}

	// Verify files were created
	files := os.ls(output_dir)!
	assert files.len > 0, 'No files generated'

	console.print_item('Generated ${files.len} markdown files:')
	for file in files {
		console.print_item('  - ${file}')

		// Verify file content
		filepath := os.join_path(output_dir, file)
		content := os.read_file(filepath)!
		assert content.len > 0, 'Generated file is empty: ${file}'
	}
	console.print_lf(1)

	// Test content validation
	console.print_header('Test 4: Content Validation')

	for file in files {
		filepath := os.join_path(output_dir, file)
		content := os.read_file(filepath)!

		// Check for required sections
		has_module_header := content.contains('# Module:')
		has_imports := content.contains('## Imports') || !content.contains('import ')
		has_valid_format := content.contains('```v')

		assert has_module_header, '${file}: Missing module header'
		assert has_valid_format || file.contains('services'), '${file}: Invalid markdown format'

		console.print_item('  ✓ ${file}: Valid content')
	}
	console.print_lf(1)

	console.print_green('✓ All CodeGenerator tests passed!')
}

// Helper: Setup test directory (copy from codeparser test)
fn setup_test_directory() string {
	test_dir := '/tmp/codegen_test_data'

	os.rmdir_all(test_dir) or {}

	current_file := @FILE
	current_dir := os.dir(current_file)

	// Navigate to codeparser testdata
	codeparser_dir := os.join_path(os.dir(current_dir), 'codeparser')
	testdata_dir := os.join_path(codeparser_dir, 'testdata')

	if !os.is_dir(testdata_dir) {
		panic('testdata directory not found at: ${testdata_dir}')
	}

	os.mkdir_all(test_dir) or { panic('Failed to create test directory') }
	copy_directory(testdata_dir, test_dir) or { panic('Failed to copy testdata: ${err}') }

	return test_dir
}

fn copy_directory(src string, dst string) ! {
	entries := os.ls(src)!

	for entry in entries {
		src_path := os.join_path(src, entry)
		dst_path := os.join_path(dst, entry)

		if os.is_dir(src_path) {
			os.mkdir_all(dst_path)!
			copy_directory(src_path, dst_path)!
		} else {
			content := os.read_file(src_path)!
			os.write_file(dst_path, content)!
		}
	}
}
