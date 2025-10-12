module encoderhero

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.ourtime
import v.reflection

// Encoder encodes a struct into HEROSCRIPT representation.
pub struct Encoder {
pub mut:
	escape_unicode bool = true
	action_name    string
	action_names   []string
	params         paramsparser.Params
}

// encode is a generic function that encodes a type into a HEROSCRIPT string.
pub fn encode[T](val T) !string {
	mut e := Encoder{
		params: paramsparser.Params{}
	}

	$if T is $struct {
		e.encode_struct[T](val)!
	} $else {
		return error('can only encode structs, got: ${typeof(val).name}')
	}
	return e.export()!
}

// export exports an encoder into encoded heroscript
pub fn (e Encoder) export() !string {
	script := e.params.export(
		pre:        '!!define.${e.action_names.join('.')}'
		indent:     ''
		skip_empty: true
	)
	return script
}

// encode the struct - single level only
pub fn (mut e Encoder) encode_struct[T](t T) ! {
	mut mytype := reflection.type_of[T](t)
	struct_attrs := attrs_get_reflection(mytype)

	mut action_name := T.name.all_after_last('.').to_lower()
	
	if 'alias' in struct_attrs {
		action_name = struct_attrs['alias'].to_lower()
	}
	e.action_names << action_name.to_lower()

	// Encode all fields recursively (including embedded)
	params := paramsparser.encode[T](t, recursive: true)!
	e.params = params

	// Validate no nested structs or struct arrays
	$for field in T.fields {
		if !should_skip_field(field.attrs) {
			val := t.$(field.name)
			
			// Check for unsupported nested structs (non-embedded, non-time)
			$if val is $struct {
				$if val !is ourtime.OurTime {
					// Embedded structs (capitalized names) are OK - they're flattened
					// Non-embedded structs are not allowed
					if !field.name[0].is_capital() {
						return error('Nested structs are not supported. Use embedded structs for inheritance. Field: ${field.name}')
					}
				}
			} $else $if val is $array {
				// Check if it's an array of structs
				if is_struct_array(val) {
					return error('Arrays of structs are not supported. Use arrays of basic types only. Field: ${field.name}')
				}
			}
		}
	}
}

// Helper function to check if field should be skipped
fn should_skip_field(attrs []string) bool {
	for attr in attrs {
		attr_clean := attr.to_lower().replace(' ', '').replace('\t', '')
		if attr_clean == 'skip' 
			|| attr_clean.starts_with('skip;')
			|| attr_clean.ends_with(';skip')
			|| attr_clean.contains(';skip;')
			{
			return true
		}
	}
	return false
}

// Helper to check if an array contains structs
fn is_struct_array[U](arr []U) bool {
	$if U is $struct {
		return true
	}
	return false
}