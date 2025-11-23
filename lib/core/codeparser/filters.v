module codeparser

import incubaid.herolib.core.code
import regex

@[params]
pub struct FilterOptions {
pub:
	module_name  string
	name_filter  string // just partial match
	is_public    bool
	has_receiver bool
}

// structs returns a filtered list of all structs found in the parsed files
pub fn (parser CodeParser) structs(options FilterOptions) []code.Struct {
	mut result := []code.Struct{}
	for _, file in parser.parsed_files {
		if options.module_name != '' && file.module_name != options.module_name {
			continue
		}
		for struct_ in file.vfile.structs() {
			if options.name_filter.len > 0 {
				if !struct_.name.contains(options.name_filter) {
					continue
				}
			}
			if options.is_public && !struct_.is_pub {
				continue
			}
			result << struct_
		}
	}
	return result
}

// functions returns a filtered list of all functions found in the parsed files
pub fn (parser CodeParser) functions(options FilterOptions) []code.Function {
	mut result := []code.Function{}
	for _, file in parser.parsed_files {
		if options.module_name != '' && file.module_name != options.module_name {
			continue
		}
		for func in file.vfile.functions() {
			if options.name_filter.len > 0 {
				if !func.name.contains(options.name_filter) {
					continue
				}
			}
			if options.is_public && !func.is_pub {
				continue
			}
			if options.has_receiver && func.receiver.typ.symbol() == '' {
				continue
			}
			result << func
		}
	}
	return result
}

// filter_public_structs returns all public structs
pub fn (parser CodeParser) filter_public_structs(module_name string) []code.Struct {
	return parser.structs(
		module_name: module_name
		is_public:   true
	)
}

// filter_public_functions returns all public functions
pub fn (parser CodeParser) filter_public_functions(module_name string) []code.Function {
	return parser.functions(
		module_name: module_name
		is_public:   true
	)
}

// filter_methods returns all functions with receivers (methods)
pub fn (parser CodeParser) filter_methods(module_name string) []code.Function {
	return parser.functions(
		module_name:  module_name
		has_receiver: true
	)
}
