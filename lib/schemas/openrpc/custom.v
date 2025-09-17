module openrpc

import json

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
		example_params[param.name] = param.schema.example_value()
	}
	
	example_call := json.encode(example_params)
	example_response := if method.result {
		method.result.schema.example_value()
	} else {
		'{"result": "success"}'
	}
	
	return example_call, example_response
}