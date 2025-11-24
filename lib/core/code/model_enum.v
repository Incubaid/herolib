module code

pub fn parse_enum(code_ string) !Enum {
	mut lines := code_.split_into_lines()
	mut comment_lines := []string{}
	mut enum_lines := []string{}
	mut in_enum := false
	mut enum_name := ''
	mut is_pub := false

	for line in lines {
		trimmed := line.trim_space()
		if !in_enum && trimmed.starts_with('//') {
			comment_lines << trimmed.trim_string_left('//').trim_space()
		} else if !in_enum && (trimmed.starts_with('enum ') || trimmed.starts_with('pub enum ')) {
			in_enum = true
			enum_lines << line

			// Extract enum name
			is_pub = trimmed.starts_with('pub ')
			mut name_part := if is_pub {
				trimmed.trim_string_left('pub enum ').trim_space()
			} else {
				trimmed.trim_string_left('enum ').trim_space()
			}

			if name_part.contains('{') {
				enum_name = name_part.all_before('{').trim_space()
			} else {
				enum_name = name_part
			}
		} else if in_enum {
			enum_lines << line

			if trimmed.starts_with('}') {
				break
			}
		}
	}

	if enum_name == '' {
		return error('Invalid enum format: could not extract enum name')
	}

	// Process enum values
	mut values := []EnumValue{}

	for i := 1; i < enum_lines.len - 1; i++ {
		line := enum_lines[i].trim_space()

		// Skip empty lines and comments
		if line == '' || line.starts_with('//') {
			continue
		}

		// Parse enum value
		parts := line.split('=').map(it.trim_space())
		value_name := parts[0]
		value_content := if parts.len > 1 { parts[1] } else { '' }

		values << EnumValue{
			name:  value_name
			value: value_content
		}
	}

	// Process comments into description
	description := comment_lines.join('\n')

	return Enum{
		name:        enum_name
		description: description
		is_pub:      is_pub
		values:      values
	}
}

pub fn (e Enum) vgen() string {
	prefix := if e.is_pub { 'pub ' } else { '' }
	comments := if e.description.trim_space() != '' {
		'// ${e.description.trim_space()}\n'
	} else {
		''
	}

	mut values_str := ''
	for value in e.values {
		if value.value != '' {
			values_str += '\n\t${value.name} = ${value.value}'
		} else {
			values_str += '\n\t${value.name}'
		}
	}

	return '${comments}${prefix}enum ${e.name} {${values_str}\n}'
}
