module codeparser

import incubaid.herolib.core.code

// list_modules returns a list of all parsed module names
pub fn (parser CodeParser) list_modules() []string {
	return parser.modules.keys()
}

// get_module_stats returns statistics for a given module
pub fn (parser CodeParser) get_module_stats(module_name string) ModuleStats {
	mut stats := ModuleStats{}
	if file_paths := parser.modules[module_name] {
		stats.file_count = file_paths.len
		for file_path in file_paths {
			if parsed_file := parser.parsed_files[file_path] {
				vfile := parsed_file.vfile
				stats.struct_count += vfile.structs().len
				stats.function_count += vfile.functions().len
				stats.const_count += vfile.consts.len
				stats.interface_count += vfile.interfaces().len
			}
		}
	}
	return stats
}

// get_parsed_file returns the parsed file for a given path
pub fn (parser CodeParser) get_parsed_file(file_path string) ?ParsedFile {
	return parser.parsed_files[file_path]
}

// all_structs returns all structs from all parsed files
pub fn (p CodeParser) all_structs() []code.Struct {
	mut all := []code.Struct{}
	for _, file in p.parsed_files {
		all << file.vfile.structs()
	}
	return all
}

// all_functions returns all functions from all parsed files
pub fn (p CodeParser) all_functions() []code.Function {
	mut all := []code.Function{}
	for _, file in p.parsed_files {
		all << file.vfile.functions()
	}
	return all
}

// all_consts returns all constants from all parsed files
pub fn (p CodeParser) all_consts() []code.Const {
	mut all := []code.Const{}
	for _, file in p.parsed_files {
		all << file.vfile.consts
	}
	return all
}

// all_imports returns a map of all unique imports
pub fn (p CodeParser) all_imports() map[string]bool {
	mut all := map[string]bool{}
	for _, file in p.parsed_files {
		for imp in file.vfile.imports {
			all[imp.mod] = true
		}
	}
	return all
}

// all_enums returns all enums from all parsed files
pub fn (p CodeParser) all_enums() []code.Enum {
	mut all := []code.Enum{}
	for _, file in p.parsed_files {
		all << file.vfile.enums()
	}
	return all
}

// all_interfaces returns all interfaces from all parsed files
pub fn (p CodeParser) all_interfaces() []code.Interface {
	mut all := []code.Interface{}
	for _, file in p.parsed_files {
		all << file.vfile.interfaces()
	}
	return all
}
