module codeparser

import incubaid.herolib.core.code

@[params]
pub struct FilterOptions {
pub:
	module_      string
	name_regex   string
	is_public    bool
	has_receiver bool
}

// structs returns a filtered list of all structs found in the parsed files
pub fn (p CodeParser) structs(options FilterOptions) []code.Struct {
	mut result := []code.Struct{}
	for _, file in p.parsed_files {
		if options.module_ != '' && file.module_name != options.module_ {
			continue
		}
		for struct_ in file.vfile.structs() {
			if options.name_regex != '' && !struct_.name.match_regex(options.name_regex) {
				continue
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
pub fn (p CodeParser) functions(options FilterOptions) []code.Function {
	mut result := []code.Function{}
	for _, file in p.parsed_files {
		if options.module_ != '' && file.module_name != options.module_ {
			continue
		}
		for func in file.vfile.functions() {
			if options.name_regex != '' && !func.name.match_regex(options.name_regex) {
				continue
			}
			if options.is_public && !func.is_pub {
				continue
			}
			if options.has_receiver && func.receiver.typ.name == '' {
				continue
			}
			result << func
		}
	}
	return result
}
