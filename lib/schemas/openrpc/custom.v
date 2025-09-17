module openrpc
import json
import freeflowuniverse.herolib.schemas.jsonschema


// In the OpenRPC specification struct
pub fn (spec OpenRPC) methods_by_object() map[string][]Method {
	mut grouped := map[string][]Method{}
	
	for method in spec.methods {
		// Extract root object from method name (e.g., "calendar.create" -> "calendar")
		parts := method.name.split('.')
		root_object := if parts.len > 1 { parts[0] } else { 'general' }
		
		if root_object !in grouped {
			grouped[root_object] = []Method{}
		}
		grouped[root_object] << method
	}
	
	return grouped
}

pub fn (spec OpenRPC) get_object_description(object_name string) string {
	// Return description for object if available
	// Implementation depends on how objects are defined in the spec
	return ''
}

pub fn (spec OpenRPC) name_fix() string {
	return spec.info.title.replace(' ', '_').to_lower()
}

// In Method struct
pub fn (method Method) example() (string, string) {
	// Generate example call and response
	// This should create realistic JSON examples based on the method schema
	
	mut example_params := map[string]string{}
	for param in method.params {
		param_schema_ref := param.schema
		example_params[param.name] = match param_schema_ref {
			openrpc.ContentDescriptor {
				match param_schema_ref.schema {
					jsonschema.Schema {
						param_schema_ref.schema.example_value()
					}
					jsonschema.Reference {
						''
					}
				}
			}
			jsonschema.Reference {
				''
			}
		}
	}
	
	example_call := json.encode(example_params)
	example_response := if method.result is openrpc.ContentDescriptor {
		result_schema_ref := method.result
		match result_schema_ref {
			openrpc.ContentDescriptor {
				match result_schema_ref.schema {
					jsonschema.Schema {
						result_schema_ref.schema.example_value()
					}
					jsonschema.Reference {
						'{"result": "success"}'
					}
				}
			}
			jsonschema.Reference {
				'{"result": "success"}'
			}
		}
	} else {
		'{"result": "success"}'
	}
	
	return example_call, example_response
}