module codeparser

import incubaid.herolib.core.code

// SearchContext provides context for a found item
pub struct SearchContext {
pub:
	file_path   string
	module_name string
	line_number int // optional, 0 if unknown
}

// find_struct searches for a struct by name
// 
// Args:
//   name string - struct name to find
//   module string - optional module filter
// Returns:
//   Struct - if found
//   error - if not found
pub fn (parser CodeParser) find_struct(name: string, module: string = '') !code.Struct {
	for _, parsed_file in parser.parsed_files {
		if module != '' && parsed_file.module_name != module {
			continue
		}

		structs := parsed_file.vfile.structs()
		for struct_ in structs {
			if struct_.name == name {
				return struct_
			}
		}
	}

	return error('struct \'${name}\' not found${if module != '' { ' in module \'${module}\'' } else { '' }}')
}

// find_function searches for a function by name
// 
// Args:
//   name string - function name to find
//   module string - optional module filter
// Returns:
//   Function - if found
//   error - if not found
pub fn (parser CodeParser) find_function(name: string, module: string = '') !code.Function {
	for _, parsed_file in parser.parsed_files {
		if module != '' && parsed_file.module_name != module {
			continue
		}

		if func := parsed_file.vfile.get_function(name) {
			return func
		}
	}

	return error('function \'${name}\' not found${if module != '' { ' in module \'${module}\'' } else { '' }}')
}

// find_interface searches for an interface by name
pub fn (parser CodeParser) find_interface(name: string, module: string = '') !code.Interface {
	for _, parsed_file in parser.parsed_files {
		if module != '' && parsed_file.module_name != module {
			continue
		}

		for item in parsed_file.vfile.items {
			if item is code.Interface {
				iface := item as code.Interface
				if iface.name == name {
					return iface
				}
			}
		}
	}

	return error('interface \'${name}\' not found${if module != '' { ' in module \'${module}\'' } else { '' }}')
}

// find_method searches for a method on a struct
// 
// Args:
//   struct_name string - name of the struct
//   method_name string - name of the method
//   module string - optional module filter
// Returns:
//   Function - if found
//   error - if not found
pub fn (parser CodeParser) find_method(struct_name: string, method_name: string, module: string = '') !code.Function {
	methods := parser.list_methods_on_struct(struct_name, module)

	for method in methods {
		if method.name == method_name {
			return method
		}
	}

	return error('method \'${method_name}\' on struct \'${struct_name}\' not found${if module != '' { ' in module \'${module}\'' } else { '' }}')
}

// find_module searches for a module by name
pub fn (parser CodeParser) find_module(module_name: string) !ParsedModule {
	if module_name !in parser.modules {
		return error('module \'${module_name}\' not found')
	}

	file_paths := parser.modules[module_name]
	
	mut stats := ModuleStats{}
	for file_path in file_paths {
		if parsed_file := parser.parsed_files[file_path] {
			stats.file_count++
			stats.struct_count += parsed_file.vfile.structs().len
			stats.function_count += parsed_file.vfile.functions().len
			stats.const_count += parsed_file.vfile.consts.len
		}
	}

	return ParsedModule{
		name:       module_name
		file_paths: file_paths
		stats:      stats
	}
}

// find_file retrieves parsed file information
pub fn (parser CodeParser) find_file(path: string) !ParsedFile {
	if path !in parser.parsed_files {
		return error('file \'${path}\' not found in parsed files')
	}

	return parser.parsed_files[path]
}

// find_structs_with_method finds all structs that have a specific method
pub fn (parser CodeParser) find_structs_with_method(method_name: string, module: string = '') []string {
	mut struct_names := []string{}

	functions := parser.list_functions(module)
	for func in functions {
		if func.name == method_name && func.receiver.name != '' {
			struct_type := func.receiver.typ.symbol()
			if struct_type !in struct_names {
				struct_names << struct_type
			}
		}
	}

	return struct_names
}

// find_callers finds all functions that call a specific function (basic text matching)
pub fn (parser CodeParser) find_callers(function_name: string, module: string = '') []code.Function {
	mut callers := []code.Function{}

	functions := parser.list_functions(module)
	for func in functions {
		if func.body.contains(function_name) {
			callers << func
		}
	}

	return callers
}