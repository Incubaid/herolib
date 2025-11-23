module codeparser

import incubaid.herolib.core.code

// list_modules returns all module names found in the codebase
pub fn (parser CodeParser) list_modules() []string {
	return parser.modules.keys()
}

// list_files returns all parsed file paths
pub fn (parser CodeParser) list_files() []string {
	return parser.parsed_files.keys()
}

// list_files_in_module returns all file paths in a specific module
pub fn (parser CodeParser) list_files_in_module(module: string) []string {
	return parser.modules[module] or { []string{} }
}

// list_structs returns all structs in the codebase (optionally filtered by module)
pub fn (parser CodeParser) list_structs(module: string = '') []code.Struct {
	mut structs := []code.Struct{}

	for _, parsed_file in parser.parsed_files {
		// Skip if module filter is provided and doesn't match
		if module != '' && parsed_file.module_name != module {
			continue
		}

		file_structs := parsed_file.vfile.structs()
		structs << file_structs
	}

	return structs
}

// list_functions returns all functions in the codebase (optionally filtered by module)
pub fn (parser CodeParser) list_functions(module: string = '') []code.Function {
	mut functions := []code.Function{}

	for _, parsed_file in parser.parsed_files {
		if module != '' && parsed_file.module_name != module {
			continue
		}

		file_functions := parsed_file.vfile.functions()
		functions << file_functions
	}

	return functions
}

// list_interfaces returns all interfaces in the codebase (optionally filtered by module)
pub fn (parser CodeParser) list_interfaces(module: string = '') []code.Interface {
	mut interfaces := []code.Interface{}

	for _, parsed_file in parser.parsed_files {
		if module != '' && parsed_file.module_name != module {
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
// 
// Args:
//   struct_name string - name of the struct
//   module string - optional module filter
pub fn (parser CodeParser) list_methods_on_struct(struct_name: string, module: string = '') []code.Function {
	mut methods := []code.Function{}

	functions := parser.list_functions(module)
	for func in functions {
		// Check if function has a receiver of the matching type
		if func.receiver.typ.symbol().contains(struct_name) {
			methods << func
		}
	}

	return methods
}

// list_imports returns all unique imports used in the codebase (optionally filtered by module)
pub fn (parser CodeParser) list_imports(module: string = '') []code.Import {
	mut imports := map[string]code.Import{}

	for _, parsed_file in parser.parsed_files {
		if module != '' && parsed_file.module_name != module {
			continue
		}

		for imp in parsed_file.vfile.imports {
			imports[imp.mod] = imp
		}
	}

	return imports.values()
}

// list_constants returns all constants in the codebase (optionally filtered by module)
pub fn (parser CodeParser) list_constants(module: string = '') []code.Const {
	mut consts := []code.Const{}

	for _, parsed_file in parser.parsed_files {
		if module != '' && parsed_file.module_name != module {
			continue
		}

		consts << parsed_file.vfile.consts
	}

	return consts
}

// get_module_stats calculates statistics for a module
pub fn (parser CodeParser) get_module_stats(module: string) ModuleStats {
	mut stats := ModuleStats{}

	file_paths := parser.list_files_in_module(module)
	stats.file_count = file_paths.len

	for _, parsed_file in parser.parsed_files {
		if parsed_file.module_name != module {
			continue
		}

		stats.struct_count += parsed_file.vfile.structs().len
		stats.function_count += parsed_file.vfile.functions().len
		stats.const_count += parsed_file.vfile.consts.len

		// Count interfaces
		for item in parsed_file.vfile.items {
			if item is code.Interface {
				stats.interface_count++
			}
		}
	}

	return stats
}