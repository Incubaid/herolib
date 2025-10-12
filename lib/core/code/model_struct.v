module code

import log
import os
import incubaid.herolib.core.texttools
import strings

pub struct Struct {
pub mut:
	name        string
	description string
	mod         string
	is_pub      bool
	embeds      []Struct          @[str: skip]
	generics    map[string]string @[str: skip]
	attrs       []Attribute
	fields      []StructField
}

// vgen_function generates a function statement for a function
pub fn (struct_ Struct) vgen() string {
	name_ := if struct_.generics.len > 0 {
		'${struct_.name}${vgen_generics(struct_.generics)}'
	} else {
		struct_.name
	}
	name := texttools.pascal_case(name_)

	prefix := if struct_.is_pub {
		'pub '
	} else {
		''
	}

	comments := if struct_.description.trim_space() != '' {
		'// ${struct_.description.trim_space()}'
	} else {
		''
	}

	priv_fields := struct_.fields.filter(!it.is_mut && !it.is_pub).map(it.vgen())
	pub_fields := struct_.fields.filter(!it.is_mut && it.is_pub).map(it.vgen())
	mut_fields := struct_.fields.filter(it.is_mut && !it.is_pub).map(it.vgen())
	pub_mut_fields := struct_.fields.filter(it.is_mut && it.is_pub).map(it.vgen())

	mut struct_str := $tmpl('templates/struct/struct.v.template')
	if false {
		result := os.execute_opt('echo "${struct_str.replace('$', '\$')}" | v fmt') or {
			log.debug(struct_str)
			panic(err)
		}
		return result.output
	}
	return struct_str
}

// parse_struct parses a struct definition string and returns a Struct object
// The input string should include the struct definition including any preceding comments
pub fn parse_struct(code_ string) !Struct {
	// Extract comments and actual struct code
	mut lines := code_.split_into_lines()
	mut comment_lines := []string{}
	mut struct_lines := []string{}
	mut in_struct := false
	mut struct_name := ''
	mut is_pub := false

	for line in lines {
		trimmed := line.trim_space()
		if !in_struct && trimmed.starts_with('//') {
			comment_lines << trimmed.trim_string_left('//').trim_space()
		} else if !in_struct && (trimmed.starts_with('struct ')
			|| trimmed.starts_with('pub struct ')) {
			in_struct = true
			struct_lines << line

			// Extract struct name
			is_pub = trimmed.starts_with('pub ')
			mut name_part := if is_pub {
				trimmed.trim_string_left('pub struct ').trim_space()
			} else {
				trimmed.trim_string_left('struct ').trim_space()
			}

			// Handle generics in struct name
			if name_part.contains('<') {
				struct_name = name_part.all_before('<').trim_space()
			} else if name_part.contains('{') {
				struct_name = name_part.all_before('{').trim_space()
			} else {
				struct_name = name_part
			}
		} else if in_struct {
			struct_lines << line

			// Check if we've reached the end of the struct
			if trimmed.starts_with('}') {
				break
			}
		}
	}

	if struct_name == '' {
		return error('Invalid struct format: could not extract struct name')
	}

	// Process the struct fields
	mut fields := []StructField{}
	mut current_section := ''

	for i := 1; i < struct_lines.len - 1; i++ { // Skip the first and last lines (struct declaration and closing brace)
		line := struct_lines[i].trim_space()

		// Skip empty lines and comments
		if line == '' || line.starts_with('//') {
			continue
		}

		// Check for section markers (pub:, mut:, pub mut:)
		if line.ends_with(':') {
			current_section = line
			continue
		}

		// Parse field
		parts := line.split_any(' \t')
		if parts.len < 2 {
			continue // Skip invalid lines
		}

		field_name := parts[0]
		field_type_str := parts[1..].join(' ')

		// Parse the type string into a Type object
		field_type := parse_type(field_type_str)

		// Determine field visibility based on section
		is_pub_field := current_section.contains('pub')
		is_mut_field := current_section.contains('mut')

		fields << StructField{
			name:   field_name
			typ:    field_type
			is_pub: is_pub_field
			is_mut: is_mut_field
		}
	}

	// Process the comments into a description
	description := comment_lines.join('\n')

	return Struct{
		name:        struct_name
		description: description
		is_pub:      is_pub
		fields:      fields
	}
}

pub struct Interface {
pub mut:
	name        string
	description string
	is_pub      bool
	embeds      []Interface @[str: skip]
	attrs       []Attribute
	fields      []StructField
	methods     []Function
}

pub fn (iface Interface) vgen() string {
	name := texttools.pascal_case(iface.name)

	prefix := if iface.is_pub {
		'pub'
	} else {
		''
	}

	mut fields := iface.fields.filter(!it.is_mut).map(it.vgen())
	mut mut_fields := iface.fields.filter(it.is_mut).map(it.vgen())

	fields << iface.methods.filter(!it.receiver.mutable).map(function_to_interface_field(it))
	mut_fields << iface.methods.filter(it.receiver.mutable).map(function_to_interface_field(it))

	mut iface_str := $tmpl('templates/interface/interface.v.template')
	if false {
		result := os.execute_opt('echo "${iface_str.replace('$', '\$')}" | v fmt') or {
			log.debug(iface_str)
			panic(err)
		}
		return result.output
	}
	return iface_str
}

pub fn function_to_interface_field(f Function) string {
	param_types := f.params.map(it.typ.vgen()).join(', ')
	return '${f.name}(${param_types}) ${f.result.typ.vgen()}'
}

pub struct StructField {
	Param
pub mut:
	comments    []Comment
	attrs       []Attribute
	description string
	default     string
	is_pub      bool
	is_mut      bool
	is_ref      bool
	anon_struct Struct @[str: skip] // sometimes fields may hold anonymous structs
	structure   Struct @[str: skip]
}

pub fn (field StructField) vgen() string {
	mut vstr := field.Param.vgen()
	if field.description != '' {
		vstr += '// ${field.description}'
	}
	return vstr
}

pub fn (structure Struct) get_type_symbol() string {
	mut symbol := if structure.mod != '' {
		'${structure.mod.all_after_last('.')}.${structure.name}'
	} else {
		structure.name
	}
	if structure.generics.len > 0 {
		symbol = '${symbol}${vgen_generics(structure.generics)}'
	}

	return symbol
}

pub fn (s Struct) typescript() string {
	name := texttools.pascal_case(s.name)
	fields := s.fields.map(it.typescript()).join_lines()
	return 'export interface ${name} {\n${fields}\n}'
}
