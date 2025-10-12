module encoderhero

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.ourtime

pub struct Decoder[T] {
pub mut:
	object T
	data   string
}

pub fn decode[T](data string) !T {
	return decode_struct[T](T{}, data)
}

// decode_struct decodes a heroscript string into a struct T
// Only supports single-level structs (no nested structs or arrays of structs)
fn decode_struct[T](_ T, data string) !T {
	mut typ := T{}
	
	$if T is $struct {
		obj_name := T.name.all_after_last('.').to_lower()
		
		// Define possible action name formats to try
		action_names_to_try := [
			'define.${obj_name}',
			'configure.${obj_name}',
			'${obj_name}.define',
			'${obj_name}.configure',
		]
		
		mut found_action_name := ''
		mut actions := []string{}
		mut action_str := '' // Declare action_str here
		mut params_str := '' // Declare params_str here
		
		// Find the action line
		actions_split := data.split('!!')
		
		for name_format in action_names_to_try {
			actions = actions_split.filter(it.contains(name_format))
			if actions.len > 0 {
				found_action_name = name_format
				break
			}
		}
		
		if found_action_name == '' {
			return error('Data does not contain expected action format for ${obj_name}\nData: ${data}')
		}
		
		if actions.len > 1 {
			return error('Multiple actions found for ${found_action_name}. Only single-level structs supported.')
		}
		
		action_str = actions[0]
		params_str = action_str.all_after(found_action_name).trim_space()
		params := paramsparser.parse(params_str) or {
			return error('Could not parse params: ${params_str}\n${err}')
		}
		
		// Decode all fields (paramsparser.decode handles embedded structs)
		typ = params.decode[T](typ)!
		
		// Validate no nested structs or struct arrays in the decoded type
		$for field in T.fields {
			if !should_skip_field_decode(field.attrs) {
				$if field.is_struct {
					// Embedded structs (capitalized) are OK
					// Non-embedded structs are not supported
					if !field.name[0].is_capital() {
						$if field.typ !is ourtime.OurTime {
							return error('Nested structs not supported. Field: ${field.name}')
						}
					}
				} $else $if field.is_array {
					// Arrays of basic types are OK, arrays of structs are not
					// This is validated at encode time, so just a safety check
				}
			}
		}
		
	} $else {
		return error("The type `${T.name}` can't be decoded. Only structs are supported.")
	}
	
	return typ
}

// Helper function to check if field should be skipped during decode
fn should_skip_field_decode(attrs []string) bool {
	for attr in attrs {
		attr_clean := attr.to_lower().replace(' ', '').replace('\t', '')
		if attr_clean == 'skip' 
			|| attr_clean.starts_with('skip;')
			|| attr_clean.ends_with(';skip')
			|| attr_clean.contains(';skip;')
			|| attr_clean == 'skipdecode'
			|| attr_clean.starts_with('skipdecode;')
			|| attr_clean.ends_with(';skipdecode')
			|| attr_clean.contains(';skipdecode;') {
			return true
		}
	}
	return false
}