module codeparser

import incubaid.herolib.core.code

// list_modules returns a list of all parsed module names
pub fn (parser CodeParser) list_modules() []string {
	return parser.modules.keys()
}

pub fn (parser CodeParser) list_files() []string {
	return parser.parsed_files.keys()
}

// list_files_in_module returns all file paths in a specific module
pub fn (parser CodeParser) list_files_in_module(module_name string) []string {
	return parser.modules[module_name] or { []string{} }
}

// list_structs returns all structs in the codebase (optionally filtered by module)
pub fn (parser CodeParser) list_structs(module_name string) []code.Struct {
	mut structs := []code.Struct{}

	for _, parsed_file in parser.parsed_files {
		// Skip if module filter is provided and doesn't match
		if module_name != '' && parsed_file.module_name != module_name {
			continue
		}

		file_structs := parsed_file.vfile.structs()
		structs << file_structs
	}

	return structs
}

// list_functions returns all functions in the codebase (optionally filtered by module)
pub fn (parser CodeParser) list_functions(module_name string) []code.Function {
	mut functions := []code.Function{}

	for _, parsed_file in parser.parsed_files {
		if module_name != '' && parsed_file.module_name != module_name {
			continue
		}

		file_functions := parsed_file.vfile.functions()
		functions << file_functions
	}

	return functions
}

// list_interfaces returns all interfaces in the codebase (optionally filtered by module)
pub fn (parser CodeParser) list_interfaces(module_name string) []code.Interface {
	mut interfaces := []code.Interface{}

	for _, parsed_file in parser.parsed_files {
		if module_name != '' && parsed_file.module_name != module_name {
			continue
		}

		// Extract interfaces from items
		for item in parsed_file.vfile.items {
			if item is code.Interface {
				interfaces << item
			}
		}
	}

	return interfaces
}

// list_methods_on_struct returns all methods (receiver functions) for a struct
pub fn (parser CodeParser) list_methods_on_struct(struct_name string, module_name string) []code.Function {
	mut methods := []code.Function{}

	functions := parser.list_functions(module_name)
	for func in functions {
		// Check if function has a receiver of the matching type
		receiver_type := func.receiver.typ.symbol()
		if receiver_type.contains(struct_name) {
			methods << func
		}
	}

	return methods
}

// list_imports returns all unique imports used in the codebase (optionally filtered by module)
pub fn (parser CodeParser) list_imports(module_name string) []code.Import {
	mut imports := map[string]code.Import{}

	for _, parsed_file in parser.parsed_files {
		if module_name != '' && parsed_file.module_name != module_name {
			continue
		}

		for imp in parsed_file.vfile.imports {
			imports[imp.mod] = imp
		}
	}

	return imports.values()
}

// list_constants returns all constants in the codebase (optionally filtered by module)
pub fn (parser CodeParser) list_constants(module_name string) []code.Const {
	mut consts := []code.Const{}

	for _, parsed_file in parser.parsed_files {
		if module_name != '' && parsed_file.module_name != module_name {
			continue
		}

		consts << parsed_file.vfile.consts
	}

	return consts
}
