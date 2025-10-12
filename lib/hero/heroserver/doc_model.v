module heroserver

import incubaid.herolib.schemas.openrpc
import incubaid.herolib.schemas.jsonschema

// DocSpec is the main object passed to the documentation template.
pub struct DocSpec {
pub mut:
	info      openrpc.Info
	methods   []DocMethod
	objects   []DocObject
	auth_info AuthDocInfo
	base_url  string // Dynamic base URL for examples
}

// DocObject represents a logical grouping of methods.
pub struct DocObject {
pub mut:
	name        string
	description string
	methods     []DocMethod
}

// DocMethod holds the information for a single method to be displayed.
pub struct DocMethod {
pub mut:
	name             string
	summary          string
	description      string
	params           []DocParam
	result           DocParam
	example_request  string
	example_response string
	endpoint_url     string
	curl_example     string
}

// DocParam represents a parameter or result in the documentation
pub struct DocParam {
pub mut:
	name        string
	description string
	type_info   string
	required    bool
	example     string
}

// AuthDocInfo contains authentication flow information
pub struct AuthDocInfo {
pub mut:
	enabled bool
	steps   []AuthStep
}

// AuthStep represents a single step in the authentication flow
pub struct AuthStep {
pub mut:
	number      int
	title       string
	method      string
	endpoint    string
	description string
	example     string
}

// DocConfig holds configuration for documentation generation
pub struct DocConfig {
pub mut:
	base_url     string = 'http://localhost:8080'
	handler_type string
	auth_enabled bool = true
}

// doc_spec_from_openrpc converts an OpenRPC specification to a documentation-friendly DocSpec.
// Processes all methods, parameters, and results with proper type extraction and example generation.
// Returns error if handler_type is empty or if OpenRPC spec is invalid.
pub fn doc_spec_from_openrpc(openrpc_spec openrpc.OpenRPC, handler_type string) !DocSpec {
	return doc_spec_from_openrpc_with_config(openrpc_spec, DocConfig{
		handler_type: handler_type
	})
}

// doc_spec_from_openrpc_with_config converts an OpenRPC specification with custom configuration
pub fn doc_spec_from_openrpc_with_config(openrpc_spec openrpc.OpenRPC, config DocConfig) !DocSpec {
	if config.handler_type.trim_space() == '' {
		return error('handler_type cannot be empty')
	}

	mut doc_spec := DocSpec{
		info:      openrpc_spec.info
		base_url:  config.base_url
		auth_info: create_auth_info_with_config(config.auth_enabled)
	}

	// Process all methods
	for method in openrpc_spec.methods {
		doc_method := process_method(method, config)!
		doc_spec.methods << doc_method
	}

	return doc_spec
}

// process_method converts a single OpenRPC method to a DocMethod
fn process_method(method openrpc.Method, config DocConfig) !DocMethod {
	// Convert parameters
	doc_params := process_parameters(method.params)!
	example_request := generate_request_example(doc_params)!

	// Convert result
	doc_result := process_result(method.result)!
	example_response := if doc_result.example.len > 0 {
		doc_result.example
	} else {
		generate_response_example(doc_result)!
	}

	// example_call := generate_example_call(doc_params)

	doc_method := DocMethod{
		name:             method.name
		summary:          method.summary
		description:      method.description
		params:           doc_params
		result:           doc_result
		example_response: example_response
		example_request:  example_request
	}

	// endpoint_url: '${config.base_url}/api/${config.handler_type}'
	// example_call:     example_call
	// curl_example:     generate_curl_example_jsonrpc(method.name, doc_params, config.base_url,
	// 	config.handler_type)

	return doc_method
}

// process_parameters converts OpenRPC parameters to DocParam array
fn process_parameters(params []openrpc.ContentDescriptorRef) ![]DocParam {
	mut doc_params := []DocParam{}

	for param in params {
		if param is openrpc.ContentDescriptor {
			type_info := extract_type_from_schema(param.schema)
			example := extract_example_from_schema(param.schema)

			doc_params << DocParam{
				name:        param.name
				description: param.description
				type_info:   type_info
				required:    param.required
				example:     example
			}
		}
	}

	return doc_params
}

// process_result converts OpenRPC result to DocParam
fn process_result(result openrpc.ContentDescriptorRef) !DocParam {
	mut doc_result := DocParam{}

	if result is openrpc.ContentDescriptor {
		type_info := extract_type_from_schema(result.schema)
		example := extract_example_from_schema(result.schema)

		doc_result = DocParam{
			name:        result.name
			description: result.description
			type_info:   type_info
			// required:    false // Results are never required
			example: example
		}
	}

	return doc_result
}

// create_auth_info_with_config creates authentication documentation based on configuration
fn create_auth_info_with_config(enabled bool) AuthDocInfo {
	if !enabled {
		return AuthDocInfo{
			enabled: false
			steps:   []
		}
	}

	return create_auth_info()
}

// extract_type_from_schema extracts the JSON Schema type from a SchemaRef.
// Returns detailed type string (e.g., 'string', 'array[integer]', 'object') for better example generation.
fn extract_type_from_schema(schema_ref jsonschema.SchemaRef) string {
	schema := match schema_ref {
		jsonschema.Schema {
			schema_ref
		}
		jsonschema.Reference {
			return 'reference'
		}
	}

	if schema.typ.len > 0 {
		// For arrays, include the item type if available
		if schema.typ == 'array' {
			if items := schema.items {
				// Handle single schema reference (most common case)
				if items is jsonschema.SchemaRef {
					item_type := extract_type_from_schema(items)
					return 'array[${item_type}]'
				}
				// Handle array of schema references (tuple validation)
				if items is []jsonschema.SchemaRef {
					if items.len > 0 {
						item_type := extract_type_from_schema(items[0])
						return 'array[${item_type}]'
					}
				}
			}
		}
		// For objects with additionalProperties, include the value type
		if schema.typ == 'object' {
			if additional := schema.additional_properties {
				value_type := extract_type_from_schema(additional)
				return 'object[${value_type}]'
			}
		}
		return schema.typ
	}
	return 'unknown'
}

// extract_example_from_schema extracts the example value from a SchemaRef
fn extract_example_from_schema(schema_ref jsonschema.SchemaRef) string {
	schema := match schema_ref {
		jsonschema.Schema {
			schema_ref
		}
		jsonschema.Reference {
			return '"reference_value"'
		}
	}

	if schema.example.str() != '' {
		return schema.example.str()
	}
	return ''
}

// generate_example_from_schema creates an example value for a parameter or result
fn generate_example_from_schema(schema_ref jsonschema.SchemaRef, param_name string) string {
	match schema_ref {
		jsonschema.Schema {
			return '"example_value"'
		}
		jsonschema.Reference {
			return '"reference_value"'
		}
	}
}

// Create authentication documentation info
fn create_auth_info() AuthDocInfo {
	return AuthDocInfo{
		enabled: true
		steps:   [
			AuthStep{
				number:      1
				title:       'Register Public Key'
				method:      'POST'
				endpoint:    '/auth/register'
				description: 'Register your public key with the server'
				example:     '{\n  "pubkey": "your_public_key_here"\n}'
			},
			AuthStep{
				number:      2
				title:       'Request Challenge'
				method:      'POST'
				endpoint:    '/auth/authreq'
				description: 'Request an authentication challenge'
				example:     '{\n  "pubkey": "your_public_key_here"\n}'
			},
			AuthStep{
				number:      3
				title:       'Submit Signature'
				method:      'POST'
				endpoint:    '/auth/auth'
				description: 'Sign the challenge and submit for authentication'
				example:     '{\n  "pubkey": "your_public_key_here",\n  "signature": "signed_challenge"\n}'
			},
			AuthStep{
				number:      4
				title:       'Use Session Key'
				method:      'ALL'
				endpoint:    '/api/{handler}/{method}'
				description: 'Include session key in Authorization header for all API calls'
				example:     'Authorization: Bearer {session_key}'
			},
		]
	}
}
