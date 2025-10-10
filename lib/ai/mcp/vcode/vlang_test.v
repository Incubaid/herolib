module vcode

import os

// Test file for the get_type_from_module function in vlang.v

// This test verifies that the get_type_from_module function correctly extracts
// struct definitions from V source files

// Helper function to create test files with struct definitions
fn create_test_files() !(string, string, string) {
	// Create a temporary directory for our test files
	test_dir := os.temp_dir()
	test_file_path := os.join_path(test_dir, 'test_type.v')

	// Create a test file with a simple struct
	test_content := 'module test_module

struct TestType {
	name string
	age int
	active bool
}

// Another struct to make sure we get the right one
struct OtherType {
	id string
}
'
	os.write_file(test_file_path, test_content) or {
		eprintln('Failed to create test file: ${err}')
		return error('Failed to create test file: ${err}')
	}

	// Create a test file with a nested struct
	nested_test_content := 'module test_module

struct NestedType {
	config map[string]string {
		required: true
	}
	data []struct {
		key string
		value string
	}
}
'
	nested_test_file := os.join_path(test_dir, 'nested_test.v')
	os.write_file(nested_test_file, nested_test_content) or {
		eprintln('Failed to create nested test file: ${err}')
		return error('Failed to create nested test file: ${err}')
	}

	return test_dir, test_file_path, nested_test_file
}

// Test function for get_type_from_module
fn test_get_type_from_module() {
	// Create test files
	test_dir, test_file_path, nested_test_file := create_test_files() or {
		eprintln('Failed to create test files: ${err}')
		assert false
		return
	}

	// Test case 1: Get a simple struct
	type_content := get_type_from_module(test_dir, 'TestType') or {
		eprintln('Failed to get type: ${err}')
		assert false
		return
	}

	// Verify the content matches what we expect
	expected := '\n\tname string\n\tage int\n\tactive bool\n}'
	assert type_content == expected, 'Expected: "${expected}", got: "${type_content}"'

	// Test case 2: Try to get a non-existent type
	non_existent := get_type_from_module(test_dir, 'NonExistentType') or {
		// This should fail, so we expect an error
		assert err.str().contains('not found in module'), 'Expected error message about type not found'
		''
	}
	assert non_existent == '', 'Expected empty string for non-existent type'

	// Test case 3: Test with nested braces in the struct
	nested_type_content := get_type_from_module(test_dir, 'NestedType') or {
		eprintln('Failed to get nested type: ${err}')
		assert false
		return
	}

	expected_nested := '\n\tconfig map[string]string {\n\t\trequired: true\n\t}\n\tdata []struct {\n\t\tkey string\n\t\tvalue string\n\t}\n}'
	assert nested_type_content == expected_nested, 'Expected: "${expected_nested}", got: "${nested_type_content}"'

	// Clean up test files
	os.rm(test_file_path) or {}
	os.rm(nested_test_file) or {}

	println('All tests for get_type_from_module passed successfully!')
}
