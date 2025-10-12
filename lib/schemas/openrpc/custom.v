module openrpc

import incubaid.herolib.schemas.jsonschema

// In Method struct
pub fn (method Method) example() (string, string) {
	// Extract user-provided examples from the OpenRPC specification
	// Build JSON manually to avoid json2.Any sumtype conflicts

	mut example_parts := []string{}
	for param in method.params {
		if param is ContentDescriptor {
			param_desc := param as ContentDescriptor
			if param_desc.schema is jsonschema.Schema {
				schema := param_desc.schema as jsonschema.Schema
				if schema.example.str() != '' {
					// Build JSON field manually to avoid sumtype conflicts
					example_parts << '"${param_desc.name}": ${schema.example.json_str()}'
				}
			}
		}
	}

	example_call := if example_parts.len > 0 {
		'{${example_parts.join(', ')}}'
	} else {
		'{}'
	}

	example_response := if method.result is ContentDescriptor {
		result_desc := method.result as ContentDescriptor
		if result_desc.schema is jsonschema.Schema {
			schema := result_desc.schema as jsonschema.Schema
			if schema.example.str() != '' {
				// Use json_str() to avoid json2.Any sumtype conflicts
				schema.example.json_str()
			} else {
				'{"result": "success"}'
			}
		} else {
			'{"result": "success"}'
		}
	} else {
		'{"result": "success"}'
	}

	return example_call, example_response
}
