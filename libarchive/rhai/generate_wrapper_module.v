module rhai

import incubaid.herolib.lang.rust
import os

// generates rhai wrapper for given source rust code
pub fn generate_wrapper_module(name string, source string, destination string) !string {
	source_pkg_info := rust.detect_source_package(source_path)!
	code := rust.read_source_code(source)!
	functions := get_functions(code)
	structs := get_structs(code)

	rhai_functions := generate_rhai_function_wrappers(functions, structs)

	// engine registration functions templated in engine.rs
	register_functions_rs := generate_rhai_register_functions(functions)
	register_types_rs := generate_rhai_register_types(structs)

	pathlib.get_file(os.join_path(destination, 'cargo.toml'))!
		.write($tmpl('./templates/cargo.toml'))

	pathlib.get_file(os.join_path(destination, 'src/engine.rs'))!
		.write($tmpl('./templates/engine.rs'))

	pathlib.get_file(os.join_path(destination, 'src/lib.rs'))!
		.write($tmpl('./templates/lib.rs'))

	pathlib.get_file(os.join_path(destination, 'src/wrapper.rs'))!
		.write($tmpl('./templates/wrapper.rs'))

	pathlib.get_file(os.join_path(destination, 'examples/example.rs'))!
		.write($tmpl('./templates/example.rs'))

	pathlib.get_file(os.join_path(destination, 'examples/example.rhai'))!
		.write(generate_example_rhai_script(code))
}
