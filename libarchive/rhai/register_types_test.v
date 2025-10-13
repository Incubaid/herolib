module rhai

import os
import incubaid.herolib.lang.rust // Import the rust module

fn test_generate_container_registration() {
	// Define the path to the test data file
	test_file_path := os.real_path(os.join_path(os.dir(@FILE), 'testdata', 'types.rs'))

	// Read the content of the test file
	rust_code_content := os.read_file(test_file_path) or {
		assert false, 'Failed to read test file ${test_file_path}: ${err}'
		return
	}

	// Extract the struct definition from the file content
	rust_def := rust.get_struct_from_content(rust_code_content, 'Container') or {
		assert false, 'Failed to extract struct Container from ${test_file_path}: ${err}'
		return
	}

	// Extract the expected registration function from the file content
	expected_output := rust.get_function_from_content(rust_code_content, 'register_container_type') or {
		assert false, 'Failed to extract function register_container_type from ${test_file_path}: ${err}'
		return
	}

	// Generate the code using the extracted struct definition
	generated_code := generate_rhai_registration(rust_def) or {
		assert false, 'generate_rhai_registration failed: ${err}'
		return
	}

	// Compare the generated code with the expected output
	// Use trim_space() on both to avoid potential leading/trailing whitespace mismatches
	mut generated_trimmed := generated_code // Create mutable copies
	mut expected_trimmed := expected_output
	generated_trimmed.trim_space() // Modify in place
	expected_trimmed.trim_space() // Modify in place
	assert generated_trimmed == expected_trimmed, 'Generated code does not match expected output.\n--- Generated:\n${generated_trimmed}\n--- Expected:\n${expected_trimmed}'

	// Optional: print the results for verification
	// println("--- Generated Code ---")
}
