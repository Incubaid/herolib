module codeparser

import incubaid.herolib.core.code

@[params]
pub struct FinderOptions {
pub:
	name        string @[required]
	struct_name string // only useful for methods on structs
	module_name string
}

// find_struct searches for a struct by name
pub fn (parser CodeParser) find_struct(args FinderOptions) !code.Struct {
	for _, parsed_file in parser.parsed_files {
		if args.module_name != '' && parsed_file.module_name != args.module_name {
			continue
		}

		structs := parsed_file.vfile.structs()
		for struct_ in structs {
			if struct_.name == args.name {
				return struct_
			}
		}
	}

	module_suffix := if args.module_name != '' { ' in module \'${args.module_name}\'' } else { '' }
	return error('struct \'${args.name}\' not found${module_suffix}')
}

// find_function searches for a function by name
pub fn (parser CodeParser) find_function(args FinderOptions) !code.Function {
	for _, parsed_file in parser.parsed_files {
		if args.module_name != '' && parsed_file.module_name != args.module_name {
			continue
		}

		if func := parsed_file.vfile.get_function(args.name) {
			return func
		}
	}

	module_suffix := if args.module_name != '' { ' in module \'${args.module_name}\'' } else { '' }
	return error('function \'${args.name}\' not found${module_suffix}')
}

// find_interface searches for an interface by name
pub fn (parser CodeParser) find_interface(args FinderOptions) !code.Interface {
	for _, parsed_file in parser.parsed_files {
		if args.module_name != '' && parsed_file.module_name != args.module_name {
			continue
		}

		for item in parsed_file.vfile.items {
			if item is code.Interface {
				iface := item as code.Interface
				if iface.name == args.name {
					return iface
				}
			}
		}
	}

	module_suffix := if args.module_name != '' { ' in module \'${args.module_name}\'' } else { '' }
	return error('interface \'${args.name}\' not found${module_suffix}')
}

// find_method searches for a method on a struct
pub fn (parser CodeParser) find_method(args FinderOptions) !code.Function {
	methods := parser.list_methods_on_struct(args.struct_name, args.module_name)

	for method in methods {
		if method.name == args.name {
			return method
		}
	}

	module_suffix := if args.module_name != '' { ' in module \'${args.module_name}\'' } else { '' }
	return error('method \'${args.name}\' on struct \'${args.struct_name}\' not found${module_suffix}')
}

// find_module searches for a module by name
pub fn (parser CodeParser) find_module(module_name string) !ParsedModule {
	if module_name !in parser.modules {
		return error('module \'${module_name}\' not found')
	}

	file_paths := parser.modules[module_name]
	stats := parser.get_module_stats(module_name)

	return ParsedModule{
		name:       module_name
		file_paths: file_paths
		stats:      stats
	}
}

// find_file retrieves parsed file information
pub fn (parser CodeParser) find_file(path string) !ParsedFile {
	if path !in parser.parsed_files {
		return error('file \'${path}\' not found in parsed files')
	}

	return parser.parsed_files[path]
}

// find_structs_with_method finds all structs that have a specific method
pub fn (parser CodeParser) find_structs_with_method(args FinderOptions) []string {
	mut struct_names := []string{}

	functions := parser.list_functions(args.module_name)
	for func in functions {
		if func.name == args.name && func.receiver.name != '' {
			struct_type := func.receiver.typ.symbol()
			if struct_type !in struct_names {
				struct_names << struct_type
			}
		}
	}

	return struct_names
}

// find_callers finds all functions that call a specific function (basic text matching)
pub fn (parser CodeParser) find_callers(args FinderOptions) []code.Function {
	mut callers := []code.Function{}

	functions := parser.list_functions(args.module_name)
	for func in functions {
		if func.body.contains(args.name) {
			callers << func
		}
	}

	return callers
}
