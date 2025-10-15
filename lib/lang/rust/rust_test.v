module rust_test

import incubaid.herolib.lang.rust
import os

fn test_extract_functions_from_content() {
	content := '
// This is a comment
/* This is a block comment */

pub fn public_function() {
	println("Hello, world!")
}

fn private_function() {
	println("Private function")
}

// Another comment
pub fn another_function() -> i32 {
	return 42
}
'
	functions := rust.extract_functions_from_content(content)

	assert functions.len == 3
	assert functions[0] == 'public_function'
	assert functions[1] == 'private_function'
	assert functions[2] == 'another_function'
}

fn test_extract_structs_from_content() {
	content := '
// This is a comment
/* This is a block comment */

pub struct PublicStruct {
	field: i32
}

struct PrivateStruct {
	field: String
}

pub struct GenericStruct<T> {
	field: T
}
'
	structs := rust.extract_structs_from_content(content)

	assert structs.len == 3
	assert structs[0] == 'PublicStruct'
	assert structs[1] == 'PrivateStruct'
	assert structs[2] == 'GenericStruct'
}

fn test_extract_imports_from_content() {
	content := '
// This is a comment
/* This is a block comment */

use std::io;
use std::fs::File;
use crate::module::function;

// Some code here
fn main() {
	println!("Hello, world!");
}
'
	imports := rust.extract_imports_from_content(content)

	assert imports.len == 3
	assert imports[0] == 'std::io'
	assert imports[1] == 'std::fs::File'
	assert imports[2] == 'crate::module::function'
}

fn test_get_module_name() {
	// Test regular file
	assert rust.get_module_name('/path/to/file.rs') == 'file'

	// Test mod.rs file
	assert rust.get_module_name('/path/to/module/mod.rs') == 'module'
}

// Helper function to create temporary test files
fn setup_test_files() !string {
	// Create temporary directory
	tmp_dir := os.join_path(os.temp_dir(), 'rust_test_${os.getpid()}')
	os.mkdir_all(tmp_dir) or { return error('Failed to create temporary directory: ${err}') }

	// Create test file
	test_file_content := '
// This is a test file
use std::io;
use std::fs::File;

pub struct TestStruct {
	field: i32
}

pub fn test_function() {
	println!("Hello, world!");
}

fn private_function() {
	println!("Private function");
}
'

	test_file_path := os.join_path(tmp_dir, 'test_file.rs')
	os.write_file(test_file_path, test_file_content) or {
		os.rmdir_all(tmp_dir) or {}
		return error('Failed to write test file: ${err}')
	}

	// Create mod.rs file
	mod_file_content := '
// This is a mod file
pub mod test_file;

pub fn mod_function() {
	println!("Mod function");
}
'

	mod_file_path := os.join_path(tmp_dir, 'mod.rs')
	os.write_file(mod_file_path, mod_file_content) or {
		os.rmdir_all(tmp_dir) or {}
		return error('Failed to write mod file: ${err}')
	}

	// Create submodule directory with mod.rs
	submod_dir := os.join_path(tmp_dir, 'submodule')
	os.mkdir_all(submod_dir) or {
		os.rmdir_all(tmp_dir) or {}
		return error('Failed to create submodule directory: ${err}')
	}

	submod_file_content := '
// This is a submodule mod file
pub fn submod_function() {
	println!("Submodule function");
}
'

	submod_file_path := os.join_path(submod_dir, 'mod.rs')
	os.write_file(submod_file_path, submod_file_content) or {
		os.rmdir_all(tmp_dir) or {}
		return error('Failed to write submodule mod file: ${err}')
	}

	// Create Cargo.toml
	cargo_content := '
[package]
name = "test_package"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = "1.0"
tokio = { version = "1.25", features = ["full"] }
'

	cargo_path := os.join_path(tmp_dir, 'Cargo.toml')
	os.write_file(cargo_path, cargo_content) or {
		os.rmdir_all(tmp_dir) or {}
		return error('Failed to write Cargo.toml: ${err}')
	}

	return tmp_dir
}

fn teardown_test_files(tmp_dir string) {
	os.rmdir_all(tmp_dir) or {}
}

fn test_list_functions_in_file() ! {
	tmp_dir := setup_test_files()!
	defer { teardown_test_files(tmp_dir) }

	test_file_path := os.join_path(tmp_dir, 'test_file.rs')
	functions := rust.list_functions_in_file(test_file_path)!

	assert functions.len == 2
	assert functions.contains('test_function')
	assert functions.contains('private_function')
}

fn test_list_structs_in_file() ! {
	tmp_dir := setup_test_files()!
	defer { teardown_test_files(tmp_dir) }

	test_file_path := os.join_path(tmp_dir, 'test_file.rs')
	structs := rust.list_structs_in_file(test_file_path)!

	assert structs.len == 1
	assert structs[0] == 'TestStruct'
}

fn test_extract_imports() ! {
	tmp_dir := setup_test_files()!
	defer { teardown_test_files(tmp_dir) }

	test_file_path := os.join_path(tmp_dir, 'test_file.rs')
	imports := rust.extract_imports(test_file_path)!

	assert imports.len == 2
	assert imports[0] == 'std::io'
	assert imports[1] == 'std::fs::File'
}

fn test_list_modules_in_directory() ! {
	tmp_dir := setup_test_files()!
	defer { teardown_test_files(tmp_dir) }

	modules := rust.list_modules_in_directory(tmp_dir)!

	// Should contain the module itself (mod.rs), test_file.rs and submodule directory
	assert modules.len == 3
	assert modules.contains(os.base(tmp_dir)) // Directory name (mod.rs)
	assert modules.contains('test_file')
	assert modules.contains('submodule')
}

fn test_extract_dependencies() ! {
	tmp_dir := setup_test_files()!
	defer { teardown_test_files(tmp_dir) }

	cargo_path := os.join_path(tmp_dir, 'Cargo.toml')
	dependencies := rust.extract_dependencies(cargo_path)!

	assert dependencies.len == 2
	assert dependencies['serde'] == '1.0'
	assert dependencies['tokio'] == '{ version = "1.25", features = ["full"] }'
}

fn test_extract_impl_methods() {
	test_impl_content := os.read_file('${os.dir(@FILE)}/test_impl.rs') or {
		assert false, 'Failed to read test_impl.rs: ${err}'
		return
	}

	functions := rust.extract_functions_from_content(test_impl_content)

	assert functions.len == 3
	assert functions[0] == 'Currency::new'
	assert functions[1] == 'Currency::to_usd'
	assert functions[2] == 'Currency::to_currency'

	println('Extracted functions:')
	for f in functions {
		println('  "${f}"')
	}
}

fn test_get_function_from_content() {
	mut content_lines := []string{}
	content_lines << '// Some comment'
	content_lines << ''
	content_lines << 'fn standalone_function() -> i32 {'
	content_lines << '    42'
	content_lines << '}'
	content_lines << ''
	content_lines << 'pub struct MyData {'
	content_lines << '    value: String,'
	content_lines << '}'
	content_lines << ''
	content_lines << 'impl MyData {'
	content_lines << '    pub fn new(value: String) -> Self {'
	content_lines << '        Self { value }'
	content_lines << '    }'
	content_lines << ''
	content_lines << '    fn internal_method(&self) {'
	content_lines << '        println!("Internal");'
	content_lines << '    }'
	content_lines << '}'
	content_lines << ''
	content_lines << '// Another comment'
	content := content_lines.join('\n')

	// Test standalone function
	decl1 := rust.get_function_from_content(content, 'standalone_function') or {
		assert false, 'Failed: ${err}'
		return
	}
	expected1 := 'fn standalone_function() -> i32 {\n    42\n}'
	assert decl1.trim_space() == expected1

	// Test struct method
	decl2 := rust.get_function_from_content(content, 'MyData::new') or {
		assert false, 'Failed: ${err}'
		return
	}
	expected2 := 'pub fn new(value: String) -> Self {\n        Self { value }\n    }'
	assert decl2.trim_space() == expected2

	// Test private struct method
	decl3 := rust.get_function_from_content(content, 'MyData::internal_method') or {
		assert false, 'Failed: ${err}'
		return
	}
	expected3 := 'fn internal_method(&self) {\n        println!("Internal");\n    }'
	assert decl3.trim_space() == expected3

	// Test function not found
	_ := rust.get_function_from_content(content, 'non_existent_function') or {
		assert err.msg() == 'Function non_existent_function not found in content'
		return
	}
	assert false, 'Expected error for non-existent function'
}

fn test_get_struct_from_content() {
	mut content_lines := []string{}
	content_lines << '// Comment'
	content_lines << 'pub struct SimpleStruct {'
	content_lines << '    field1: i32,'
	content_lines << '}'
	content_lines << ''
	content_lines << 'struct GenericStruct<T> {'
	content_lines << '    data: T,'
	content_lines << '}'
	content_lines << ''
	content_lines << '// Another struct'
	content_lines << 'pub struct ComplexStruct<A, B> where A: Clone {'
	content_lines << '    a: A,'
	content_lines << '    b: B,'
	content_lines << '    c: Vec<String>,'
	content_lines << '}'
	content_lines << ''
	content_lines << 'struct EmptyStruct;'
	content_lines << ''
	content_lines << 'struct StructWithImpl {'
	content_lines << '    val: bool,'
	content_lines << '}'
	content_lines << ''
	content_lines << 'impl StructWithImpl {'
	content_lines << '    fn method() {}'
	content_lines << '}'
	content := content_lines.join('\n')

	// Test simple struct
	decl1 := rust.get_struct_from_content(content, 'SimpleStruct') or {
		assert false, 'Failed: ${err}'
		return
	}
	expected1 := 'pub struct SimpleStruct {\n    field1: i32,\n}'
	assert decl1.trim_space() == expected1

	// Test generic struct
	decl2 := rust.get_struct_from_content(content, 'GenericStruct') or {
		assert false, 'Failed: ${err}'
		return
	}
	expected2 := 'struct GenericStruct<T> {\n    data: T,\n}'
	assert decl2.trim_space() == expected2

	// Test complex struct
	decl3 := rust.get_struct_from_content(content, 'ComplexStruct') or {
		assert false, 'Failed: ${err}'
		return
	}
	expected3 := 'pub struct ComplexStruct<A, B> where A: Clone {\n    a: A,\n    b: B,\n    c: Vec<String>,\n}'
	assert decl3.trim_space() == expected3

	// Test empty struct
	decl4 := rust.get_struct_from_content(content, 'EmptyStruct') or {
		assert false, 'Failed: ${err}'
		return
	}
	expected4 := 'struct EmptyStruct;'
	assert decl4.trim_space() == expected4

	// Test struct with impl
	decl5 := rust.get_struct_from_content(content, 'StructWithImpl') or {
		assert false, 'Failed: ${err}'
		return
	}
	expected5 := 'struct StructWithImpl {\n    val: bool,\n}'
	assert decl5.trim_space() == expected5

	// Test struct not found
	_ := rust.get_struct_from_content(content, 'non_existent_struct') or {
		assert err.msg() == 'Struct non_existent_struct not found in content'
		return
	}
	assert false, 'Expected error for non-existent struct'
}

fn test_get_struct_from_file() ! {
	tmp_dir := setup_test_files()!
	defer { teardown_test_files(tmp_dir) }

	test_file_path := os.join_path(tmp_dir, 'test_file.rs')
	structs := rust.list_structs_in_file(test_file_path)!

	assert structs.len == 1
	assert structs[0] == 'TestStruct'
}

fn test_get_struct_from_module() ! {
	tmp_dir := setup_test_files()!
	defer { teardown_test_files(tmp_dir) }

	modules := rust.list_modules_in_directory(tmp_dir)!

	// Should contain the module itself (mod.rs), test_file.rs and submodule directory
	assert modules.len == 3
	assert modules.contains(os.base(tmp_dir)) // Directory name (mod.rs)
	assert modules.contains('test_file')
	assert modules.contains('submodule')
}
