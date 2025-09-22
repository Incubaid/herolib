module openrpc

import json
import x.json2
import freeflowuniverse.herolib.schemas.jsonschema

// In Method struct
pub fn (method Method) example() (string, string) {
	// Extract user-provided examples from the OpenRPC specification

	mut example_params := map[string]json2.Any{}
	for param in method.params {
		if param is ContentDescriptor {
			param_desc := param as ContentDescriptor
			if param_desc.schema is jsonschema.Schema {
				schema := param_desc.schema as jsonschema.Schema
				if schema.example.str() != '' {
					example_params[param_desc.name] = schema.example
				}
			}
		}
	}

	example_call := json.encode(example_params)

	example_response := if method.result is ContentDescriptor {
		result_desc := method.result as ContentDescriptor
		if result_desc.schema is jsonschema.Schema {
			schema := result_desc.schema as jsonschema.Schema
			if schema.example.str() != '' {
				json.encode(schema.example)
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
