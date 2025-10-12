module rhai

import strings
import incubaid.herolib.lang.rust

// generate_rhai_registration generates Rust code to register a Rust struct and its fields with Rhai.
// Input: rust_struct_definition - A string containing the Rust struct definition.
// Output: A string containing the generated Rust registration function, or an error string.
pub fn generate_rhai_registration(rust_struct_definition string) !string {
	mut struct_name := ''
	mut fields := map[string]string{} // field_name: field_type

	// --- 1. Parse the struct definition using the rust module ---
	struct_info := rust.parse_rust_struct(rust_struct_definition) or {
		return error('Failed to parse Rust struct definition: ${err}')
	}

	struct_name = struct_info.struct_name
	fields = struct_info.fields.clone() // Explicitly clone the map

	// --- 2. Generate the Rust registration code ---
	mut sb := strings.new_builder(1024)
	struct_name_lower := struct_name.to_lower()

	// sb.writeln('/// Register ${struct_name} type with the Rhai engine')
	sb.writeln('fn register_${struct_name_lower}_type(engine: &mut Engine) -> Result<(), Box<EvalAltResult>> {')
	// Register the type itself
	sb.writeln('\t// Register ${struct_name} type')
	sb.writeln('\tengine.register_type_with_name::<${struct_name}>("${struct_name}");')
	sb.writeln('')
	sb.writeln('\t// Register getters for ${struct_name} properties')

	// Register getters for each field
	for field_name, field_type in fields {
		match field_type {
			'String' {
				sb.writeln('\tengine.register_get("${field_name}", |obj: &mut ${struct_name}| obj.${field_name}.clone());')
			}
			'bool' {
				sb.writeln('\tengine.register_get("${field_name}", |obj: &mut ${struct_name}| obj.${field_name});')
			}
			'Option<String>' {
				sb.writeln('\tengine.register_get("${field_name}", |obj: &mut ${struct_name}| {')
				sb.writeln('\t\tmatch &obj.${field_name} {')
				sb.writeln('\t\t\tSome(val) => val.clone(),')
				sb.writeln('\t\t\tNone => "".to_string(), // Return empty string for None')
				sb.writeln('\t\t}')
				sb.writeln('\t});')
			}
			'Vec<String>' {
				sb.writeln('\tengine.register_get("${field_name}", |obj: &mut ${struct_name}| {')
				sb.writeln('\t\tlet mut array = rhai::Array::new();')
				sb.writeln('\t\tfor item in &obj.${field_name} {')
				sb.writeln('\t\t\tarray.push(rhai::Dynamic::from(item.clone()));')
				sb.writeln('\t\t}')
				sb.writeln('\t\tarray')
				sb.writeln('\t});')
			}
			'HashMap<String, String>' {
				sb.writeln('\tengine.register_get("${field_name}", |obj: &mut ${struct_name}| {')
				sb.writeln('\t\tlet mut map = rhai::Map::new();')
				sb.writeln('\t\tfor (k, v) in &obj.${field_name} {')
				sb.writeln('\t\t\tmap.insert(k.clone().into(), v.clone().into());')
				sb.writeln('\t\t}')
				sb.writeln('\t\tmap')
				sb.writeln('\t});')
			}
			else {
				// Handle other types like Option<CustomType>, Vec<CustomType>, etc.
				// For now, just add a TODO comment
				sb.writeln('\t// TODO: Register getter for field: ${field_name} (type: ${field_type}) - Add appropriate conversion if needed.')
			}
		}
	}

	sb.writeln('')
	sb.writeln('\tOk(())')
	sb.writeln('}')

	return sb.str()
}

// Example Usage (within the V module context):
// rust_def := "" // The rust struct definition string from the comment
// generated_code := generate_rhai_registration(rust_def) or {
//     eprintln('Error generating code: ${err}')
//     return
// }
// println(generated_code)
