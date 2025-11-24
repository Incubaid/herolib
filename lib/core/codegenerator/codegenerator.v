module codegenerator

import incubaid.herolib.core.codeparser
import incubaid.herolib.core.pathlib
import incubaid.herolib.core.code
import incubaid.herolib.core.texttools
import os

pub struct CodeGenerator {
pub mut:
	parser     codeparser.CodeParser
	output_dir string
	format     bool
}

// generate_all generates markdown docs for all modules
pub fn (mut gen CodeGenerator) generate_all() ! {
	modules := gen.parser.list_modules()

	for module_name in modules {
		gen.generate_module(module_name)!
	}
}

// generate_module generates markdown for a single module
pub fn (mut gen CodeGenerator) generate_module(module_name string) ! {
	md := gen.module_to_markdown(module_name)!

	// Convert module name to filename: incubaid.herolib.core.code -> code___core___code.md
	filename := gen.module_to_filename(module_name)
	filepath := os.join_path(gen.output_dir, filename)

	mut file := pathlib.get_file(path: filepath, create: true)!
	file.write(md)!
}

// module_to_markdown generates complete markdown for a module
pub fn (gen CodeGenerator) module_to_markdown(module_name string) !string {
	module_obj := gen.parser.find_module(module_name)!

	mut md := ''

	// Use template for module header
	md += $tmpl('templates/module.md.template')

	// Imports section
	imports := gen.parser.list_imports(module_name)
	if imports.len > 0 {
		md += gen.imports_section(imports)
	}

	// Constants section
	consts := gen.parser.list_constants(module_name)
	if consts.len > 0 {
		md += gen.constants_section(consts)
	}

	// Structs section
	structs := gen.parser.list_structs(module_name)
	if structs.len > 0 {
		md += gen.structs_section(structs, module_name)
	}

	// Functions section
	functions := gen.parser.list_functions(module_name)
	if functions.len > 0 {
		md += gen.functions_section(functions, module_name)
	}

	// Interfaces section
	interfaces := gen.parser.list_interfaces(module_name)
	if interfaces.len > 0 {
		md += gen.interfaces_section(interfaces)
	}

	return md
}

// imports_section generates imports documentation
fn (gen CodeGenerator) imports_section(imports []code.Import) string {
	mut md := '## Imports\n\n'

	for imp in imports {
		md += '- `' + imp.mod + '`\n'
	}
	md += '\n'

	return md
}

// constants_section generates constants documentation
fn (gen CodeGenerator) constants_section(consts []code.Const) string {
	mut md := '## Constants\n\n'

	for const_ in consts {
		md += '- `' + const_.name + '` = `' + const_.value + '`\n'
	}
	md += '\n'

	return md
}

// structs_section generates structs documentation
fn (gen CodeGenerator) structs_section(structs []code.Struct, module_name string) string {
	mut md := '## Structs\n\n'

	for struct_ in structs {
		md += gen.struct_to_markdown(struct_)
	}

	return md
}

// functions_section generates functions documentation
fn (gen CodeGenerator) functions_section(functions []code.Function, module_name string) string {
	mut md := '## Functions & Methods\n\n'

	// Separate regular functions and methods
	regular_functions := functions.filter(it.receiver.typ.symbol() == '')
	methods := functions.filter(it.receiver.typ.symbol() != '')

	// Regular functions
	if regular_functions.len > 0 {
		md += '### Functions\n\n'
		for func in regular_functions {
			md += gen.function_to_markdown(func)
		}
	}

	// Methods (grouped by struct)
	if methods.len > 0 {
		md += '### Methods\n\n'
		structs := gen.parser.list_structs(module_name)

		for struct_ in structs {
			struct_methods := methods.filter(it.receiver.typ.symbol().contains(struct_.name))
			if struct_methods.len > 0 {
				md += '#### ' + struct_.name + '\n\n'
				for method in struct_methods {
					md += gen.function_to_markdown(method)
				}
			}
		}
	}

	return md
}

// interfaces_section generates interfaces documentation
fn (gen CodeGenerator) interfaces_section(interfaces []code.Interface) string {
	mut md := '## Interfaces\n\n'

	for iface in interfaces {
		md += '### ' + iface.name + '\n\n'
		if iface.description != '' {
			md += iface.description + '\n\n'
		}
		md += '```v\n'
		if iface.is_pub {
			md += 'pub '
		}
		md += 'interface ' + iface.name + ' {\n'
		for field in iface.fields {
			md += '  ' + field.name + ': ' + field.typ.symbol() + '\n'
		}
		md += '}\n```\n\n'
	}

	return md
}

// struct_to_markdown converts struct to markdown
fn (gen CodeGenerator) struct_to_markdown(struct_ code.Struct) string {
	mut md := '### '

	if struct_.is_pub {
		md += '**pub** '
	}

	md += 'struct ' + struct_.name + '\n\n'

	if struct_.description != '' {
		md += struct_.description + '\n\n'
	}

	md += '```v\n'
	if struct_.is_pub {
		md += 'pub '
	}
	md += 'struct ' + struct_.name + ' {\n'
	for field in struct_.fields {
		md += '	' + field.name + ' ' + field.typ.symbol() + '\n'
	}
	md += '}\n'
	md += '```\n\n'

	// Field documentation
	if struct_.fields.len > 0 {
		md += '**Fields:**\n\n'
		for field in struct_.fields {
			visibility := if field.is_pub { 'public' } else { 'private' }
			mutability := if field.is_mut { ', mutable' } else { '' }
			md += '- `' + field.name + '` (`' + field.typ.symbol() + '`)' + mutability + ' - ' +
				visibility + '\n'
			if field.description != '' {
				md += '  - ' + field.description + '\n'
			}
		}
		md += '\n'
	}

	return md
}

// function_to_markdown converts function to markdown
fn (gen CodeGenerator) function_to_markdown(func code.Function) string {
	mut md := ''

	// Function signature
	signature := gen.function_signature(func)
	md += '- `' + signature + '`\n'

	// Description
	if func.description != '' {
		md += '  - *' + func.description + '*\n'
	}

	// Parameters
	if func.params.len > 0 {
		md += '\n  **Parameters:**\n'
		for param in func.params {
			md += '  - `' + param.name + '` (`' + param.typ.symbol() + '`)'
			if param.description != '' {
				md += ' - ' + param.description
			}
			md += '\n'
		}
	}

	// Return type
	if func.result.typ.symbol() != '' {
		md += '\n  **Returns:** `' + func.result.typ.symbol() + '`\n'
	}

	md += '\n'

	return md
}

// function_signature generates a function signature string
fn (gen CodeGenerator) function_signature(func code.Function) string {
	mut sig := if func.is_pub { 'pub ' } else { '' }

	if func.receiver.name != '' {
		sig += '(' + func.receiver.name + ' ' + func.receiver.typ.symbol() + ') '
	}

	sig += func.name

	// Parameters
	params := func.params.map(it.name + ': ' + it.typ.symbol()).join(', ')
	sig += '(' + params + ')'

	// Return type
	if func.result.typ.symbol() != '' {
		sig += ' -> ' + func.result.typ.symbol()
	}

	return sig
}

// module_to_filename converts module name to filename
// e.g., incubaid.herolib.core.code -> code__core__code.md
pub fn (gen CodeGenerator) module_to_filename(module_name string) string {
	// Get last part after last dot, then add __ and rest in reverse
	parts := module_name.split('.')
	filename := parts[parts.len - 1]

	return filename + '.md'
}
