module rhai

import incubaid.herolib.lang.rhai
import incubaid.herolib.core.texttools
// import strings // No longer needed directly here
import incubaid.herolib.lang.rust
import os

const test_data_file = os.dir(@FILE) + '/testdata/functions.rs' // Use path relative to this test file

fn testsuite_begin() {
	// Optional: Setup code before tests run
	if !os.exists(test_data_file) {
		panic('Test data file not found: ${test_data_file}')
	}
}

fn testsuite_end() {
	// Optional: Teardown code after tests run
}

// --- Test Cases ---

fn test_generate_wrapper_simple_function() {
	rust_fn_name := 'add'
	// Call directly using suspected correct function name
	rust_fn_sig := rust.get_function_from_file(test_data_file, rust_fn_name) or {
		assert false, 'Failed to get function signature for ${rust_fn_name}: ${err}'
		return
	}
	struct_decls := []string{}

	generated_output := rhai.generate_rhai_function_wrapper(rust_fn_sig, struct_decls) or {
		assert false, 'Wrapper generation failed for ${rust_fn_name}: ${err}'
		return
	}
	verify_rhai_wrapper(rust_fn_sig, struct_decls, generated_output) or {
		assert false, 'Verification failed for ${rust_fn_name}: ${err}'
	}
}

fn test_generate_wrapper_immutable_method() {
	rust_fn_name := 'get_name'
	struct_name := 'MyStruct'
	// Use get_function_from_file for methods too
	rust_fn_sig := rust.get_function_from_file(test_data_file, rust_fn_name) or { // Using get_function_from_file
		assert false, 'Failed to get method signature for ${struct_name}::${rust_fn_name}: ${err}'
		return
	}
	// Call directly using suspected correct function name
	struct_def := rust.get_struct_from_file(test_data_file, struct_name) or {
		assert false, 'Failed to get struct def for ${struct_name}: ${err}'
		return
	}
	struct_decls := [struct_def]

	generated_output := rhai.generate_rhai_function_wrapper(rust_fn_sig, struct_decls) or {
		assert false, 'Wrapper generation failed for ${struct_name}::${rust_fn_name}: ${err}'
		return
	}
	verify_rhai_wrapper(rust_fn_sig, struct_decls, generated_output) or {
		assert false, 'Verification failed for ${struct_name}::${rust_fn_name}: ${err}'
	}
}

fn test_generate_wrapper_mutable_method() {
	rust_fn_name := 'set_name'
	struct_name := 'MyStruct'
	// Use get_function_from_file for methods too
	rust_fn_sig := rust.get_function_from_file(test_data_file, rust_fn_name) or { // Using get_function_from_file
		assert false, 'Failed to get method signature for ${struct_name}::${rust_fn_name}: ${err}'
		return
	}
	// Call directly using suspected correct function name
	struct_def := rust.get_struct_from_file(test_data_file, struct_name) or {
		assert false, 'Failed to get struct def for ${struct_name}: ${err}'
		return
	}
	struct_decls := [struct_def]

	generated_output := rhai.generate_rhai_function_wrapper(rust_fn_sig, struct_decls) or {
		assert false, 'Wrapper generation failed for ${struct_name}::${rust_fn_name}: ${err}'
		return
	}
	verify_rhai_wrapper(rust_fn_sig, struct_decls, generated_output) or {
		assert false, 'Verification failed for ${struct_name}::${rust_fn_name}: ${err}'
	}
}

fn test_generate_wrapper_function_returning_result() {
	rust_fn_name := 'load_config'
	// Call directly using suspected correct function name
	rust_fn_sig := rust.get_function_from_file(test_data_file, rust_fn_name) or {
		assert false, 'Failed to get function signature for ${rust_fn_name}: ${err}'
		return
	}
	// Need struct def for Config if wrapper needs it (likely for return type)
	struct_name := 'Config'
	// Call directly using suspected correct function name
	struct_def := rust.get_struct_from_file(test_data_file, struct_name) or {
		assert false, 'Failed to get struct def for ${struct_name}: ${err}'
		return
	}
	struct_decls := [struct_def]

	generated_output := rhai.generate_rhai_function_wrapper(rust_fn_sig, struct_decls) or {
		assert false, 'Wrapper generation failed for ${rust_fn_name}: ${err}'
		return
	}
	verify_rhai_wrapper(rust_fn_sig, struct_decls, generated_output) or {
		assert false, 'Verification failed for ${rust_fn_name}: ${err}'
	}
}

fn test_generate_wrapper_function_returning_pathbuf() {
	rust_fn_name := 'get_home_dir'
	// Call directly using suspected correct function name
	rust_fn_sig := rust.get_function_from_file(test_data_file, rust_fn_name) or {
		assert false, 'Failed to get function signature for ${rust_fn_name}: ${err}'
		return
	}
	struct_decls := []string{}

	generated_output := rhai.generate_rhai_function_wrapper(rust_fn_sig, struct_decls) or {
		assert false, 'Wrapper generation failed for ${rust_fn_name}: ${err}'
		return
	}
	verify_rhai_wrapper(rust_fn_sig, struct_decls, generated_output) or {
		assert false, 'Verification failed for ${rust_fn_name}: ${err}'
	}
}

fn test_generate_wrapper_function_with_vec() {
	rust_fn_name := 'list_files'
	// Call directly using suspected correct function name
	rust_fn_sig := rust.get_function_from_file(test_data_file, rust_fn_name) or {
		assert false, 'Failed to get function signature for ${rust_fn_name}: ${err}'
		return
	}
	struct_decls := []string{}

	generated_output := rhai.generate_rhai_function_wrapper(rust_fn_sig, struct_decls) or {
		assert false, 'Wrapper generation failed for ${rust_fn_name}: ${err}'
		return
	}
	verify_rhai_wrapper(rust_fn_sig, struct_decls, generated_output) or {
		assert false, 'Verification failed for ${rust_fn_name}: ${err}'
	}
}
