module heroserver

import incubaid.herolib.schemas.jsonschema

// ============================================================================
// Request Example Generation
// ============================================================================

// generate_curl_example creates a curl command for a JSON-RPC method.
// Returns a properly formatted curl command with JSON-RPC 2.0 wrapper.
pub fn generate_curl_example(method_name string, params_json string, endpoint_url string) string {
	jsonrpc_request := '{"jsonrpc":"2.0","method":"${method_name}","params":${params_json},"id":1}'
	escaped_request := jsonrpc_request.replace("'", "'\\''")
	return "curl -X POST '${endpoint_url}' -H 'Content-Type: application/json' -d '${escaped_request}'"
}

// generate_request_example generates a JSON example from DocParam array.
// Extracts example values from the schema to create proper params.
// For single simple parameters, returns just the value.
// For multiple or complex parameters, returns a JSON object.
fn generate_request_example(params []DocParam) !string {
	if params.len == 0 {
		return '{}'
	}

	// Single parameter with simple type (not object/array) - return just the value
	if params.len == 1 {
		example := params[0].example.trim_space()
		if !example.starts_with('{') && !example.starts_with('[') {
			return example
		}
	}

	// Multiple parameters or complex type - return JSON object
	mut parts := []string{}
	for param in params {
		parts << '"${param.name}":${param.example}'
	}
	return '{${parts.join(',')}}'
}

// ============================================================================
// Schema Example Extraction
// ============================================================================

// extract_example_from_schema extracts the example value from a schema.
// If no example is defined, returns an empty placeholder.
pub fn extract_example_from_schema(schema_ref jsonschema.SchemaRef) string {
	schema := match schema_ref {
		jsonschema.Schema { schema_ref }
		jsonschema.Reference { return '{}' }
	}

	example_str := schema.example.json_str()
	if example_str != '' && example_str != '[]' && example_str != '{}' && example_str != 'null' {
		return example_str
	}
	return '{}'
}
