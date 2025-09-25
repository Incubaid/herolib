module jsonschema

pub fn (schema Schema) type_() string {
	return schema.typ.str()
}

// // example_value generates a basic example value based on the schema type.
// // Returns a JSON-formatted string appropriate for the schema type.
// pub fn (schema Schema) example_value[T](model T) T {
// 	obj := T{}
// 	return obj
// 	// // Check if schema has an explicit example value (ignore empty arrays which indicate no example)
// 	// example_str := schema.example.str()
// 	// println('example_str: ${example_str}')
// 	// if example_str != '' && example_str != '[]' {
// 	// 	// For object examples, return the JSON string as-is
// 	// 	if schema.typ == 'object' || example_str.starts_with('{') {
// 	// 		return example_str
// 	// 	}
// 	// 	// For string types, ensure proper JSON formatting with quotes
// 	// 	if schema.typ == 'string' && !example_str.starts_with('"') {
// 	// 		return '"${example_str}"'
// 	// 	}
// 	// 	return example_str
// 	// }

// 	// // Generate type-based example when no explicit example is provided
// 	// match schema.typ {
// 	// 	'string' { return '"example_value"' }
// 	// 	'integer', 'number' { return '42' }
// 	// 	'boolean' { return 'true' }
// 	// 	'array' { return '[]' }
// 	// 	'object' { return '{}' }
// 	// 	else { return '"example_value"' }
// 	// }
// }
