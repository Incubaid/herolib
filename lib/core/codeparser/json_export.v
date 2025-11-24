module codeparser

import json
import incubaid.herolib.core.code

// JSON export structures
pub struct CodeParserJSON {
pub mut:
	root_dir string
	modules  map[string]ModuleJSON
	summary  SummaryJSON
}

pub struct ModuleJSON {
pub mut:
	name    string
	files   map[string]FileJSON
	stats   ModuleStats
	imports []string
}

pub struct FileJSON {
pub:
	path        string
	module_name string
	items_count int
	structs     []StructJSON
	functions   []FunctionJSON
	interfaces  []InterfaceJSON
	enums       []EnumJSON
	constants   []ConstJSON
}

pub struct StructJSON {
pub:
	name        string
	is_pub      bool
	field_count int
	description string
}

pub struct FunctionJSON {
pub:
	name       string
	is_pub     bool
	has_return bool
	params     int
	receiver   string
}

pub struct InterfaceJSON {
pub:
	name        string
	is_pub      bool
	description string
}

pub struct EnumJSON {
pub:
	name        string
	is_pub      bool
	value_count int
	description string
}

pub struct ConstJSON {
pub:
	name  string
	value string
}

pub struct SummaryJSON {
pub mut:
	total_files      int
	total_modules    int
	total_structs    int
	total_functions  int
	total_interfaces int
	total_enums      int
}

// to_json exports the complete code structure to JSON
//
// Args:
//   module_name - optional module filter (if empty, exports all modules)
// Returns:
//   JSON string representation
pub fn (parser CodeParser) to_json(module_name string) !string {
	mut result := CodeParserJSON{
		root_dir: parser.root_dir
		modules:  map[string]ModuleJSON{}
		summary:  SummaryJSON{}
	}

	modules_to_process := if module_name != '' {
		if module_name in parser.modules {
			[module_name]
		} else {
			return error('module \'${module_name}\' not found')
		}
	} else {
		parser.list_modules()
	}

	for mod_name in modules_to_process {
		file_paths := parser.modules[mod_name]
		mut module_json := ModuleJSON{
			name:    mod_name
			files:   map[string]FileJSON{}
			imports: []string{}
		}

		for file_path in file_paths {
			if parsed_file := parser.parsed_files[file_path] {
				vfile := parsed_file.vfile

				// Build structs JSON
				mut structs_json := []StructJSON{}
				for struct_ in vfile.structs() {
					structs_json << StructJSON{
						name:        struct_.name
						is_pub:      struct_.is_pub
						field_count: struct_.fields.len
						description: struct_.description
					}
				}

				// Build functions JSON
				mut functions_json := []FunctionJSON{}
				for func in vfile.functions() {
					functions_json << FunctionJSON{
						name:       func.name
						is_pub:     func.is_pub
						has_return: func.has_return
						params:     func.params.len
						receiver:   func.receiver.typ.symbol()
					}
				}

				// Build interfaces JSON
				mut interfaces_json := []InterfaceJSON{}
				for item in vfile.items {
					if item is code.Interface {
						iface := item as code.Interface
						interfaces_json << InterfaceJSON{
							name:        iface.name
							is_pub:      iface.is_pub
							description: iface.description
						}
					}
				}

				// Build enums JSON
				mut enums_json := []EnumJSON{}
				for enum_ in vfile.enums() {
					enums_json << EnumJSON{
						name:        enum_.name
						is_pub:      enum_.is_pub
						value_count: enum_.values.len
						description: enum_.description
					}
				}

				// Build constants JSON
				mut consts_json := []ConstJSON{}
				for const_ in vfile.consts {
					consts_json << ConstJSON{
						name:  const_.name
						value: const_.value
					}
				}

				file_json := FileJSON{
					path:        file_path
					module_name: vfile.mod
					items_count: vfile.items.len
					structs:     structs_json
					functions:   functions_json
					interfaces:  interfaces_json
					enums:       enums_json
					constants:   consts_json
				}

				module_json.files[file_path] = file_json

				// Add imports to module level
				for imp in vfile.imports {
					if imp.mod !in module_json.imports {
						module_json.imports << imp.mod
					}
				}

				// Update summary
				result.summary.total_structs += structs_json.len
				result.summary.total_functions += functions_json.len
				result.summary.total_interfaces += interfaces_json.len
				result.summary.total_enums += enums_json.len
			}
		}

		module_json.stats = parser.get_module_stats(mod_name)
		result.modules[mod_name] = module_json
		result.summary.total_modules++
	}

	return json.encode_pretty(result)
}
