module heroserver

import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.schemas.jsonschema

// DocSpec is the main object passed to the documentation template.
pub struct DocSpec {
pub mut:
	info      openrpc.Info
	methods   []DocMethod
	objects   []DocObject
	auth_info AuthDocInfo
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
	example_call     string
	example_response string
	endpoint_url     string
	curl_example     string // New field for curl command
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
	steps []AuthStep
}

pub struct AuthStep {
pub mut:
	number      int
	title       string
	method      string
	endpoint    string
	description string
	example     string
}

// doc_spec_from_openrpc converts an OpenRPC specification to a documentation-friendly DocSpec.
// Processes all methods, parameters, and results with proper type extraction and example generation.
// Returns error if handler_type is empty or if OpenRPC spec is invalid.
pub fn doc_spec_from_openrpc(openrpc_spec openrpc.OpenRPC, handler_type string) !DocSpec {
	if handler_type.trim_space() == '' {
		return error('handler_type cannot be empty')
	}
	mut doc_spec := DocSpec{
		info:      openrpc_spec.info
		auth_info: create_auth_info()
	}

	for method in openrpc_spec.methods {
		// Convert parameters
		mut doc_params := []DocParam{}
		for param in method.params {
			if param is openrpc.ContentDescriptor {
				type_info := extract_type_from_schema(param.schema)
				example := generate_example_from_schema(param.schema, param.name)

				doc_param := DocParam{
					name:        param.name
					description: param.description
					required:    param.required
					type_info:   type_info
					example:     example
				}
				doc_params << doc_param
			}
		}

		// Convert result
		mut doc_result := DocParam{}
		if method.result is openrpc.ContentDescriptor {
			result_cd := method.result as openrpc.ContentDescriptor
			type_info := extract_type_from_schema(result_cd.schema)
			example := generate_example_from_schema(result_cd.schema, result_cd.name)

			doc_result = DocParam{
				name:        result_cd.name
				description: result_cd.description
				required:    result_cd.required
				type_info:   type_info
				example:     example
			}
		}

		// Generate example call and response
		example_call := generate_example_call(doc_params)
		example_response := generate_example_response(doc_result)

		// Generate JSON-RPC example call
		jsonrpc_call := generate_jsonrpc_example_call(method.name, doc_params)

		mut doc_method := DocMethod{
			name:             method.name
			summary:          method.summary
			description:      method.description
			params:           doc_params
			result:           doc_result
			endpoint_url:     '/api/${handler_type}'
			example_call:     example_call
			example_response: example_response
			curl_example:     '' // Will be set later with proper base URL
		}

		// Generate curl example with localhost as default using JSON-RPC format
		doc_method.curl_example = generate_curl_example_jsonrpc(method.name, doc_params,
			'http://localhost:8080', handler_type)
		doc_spec.methods << doc_method
	}

	return doc_spec
}

// extract_type_from_schema extracts the JSON Schema type from a SchemaRef.
// Returns the type string (e.g., 'string', 'object', 'array') or 'reference'/'unknown' for edge cases.
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
		return schema.typ
	}
	return 'unknown'
}

// generate_example_from_schema creates an example value for a parameter or result.
// Uses the jsonschema.Schema.example_value() method with parameter name customization for strings.
// Returns properly formatted JSON values based on the schema type.
fn generate_example_from_schema(schema_ref jsonschema.SchemaRef, param_name string) string {
	schema := match schema_ref {
		jsonschema.Schema {
			schema_ref
		}
		jsonschema.Reference {
			return '"reference_value"'
		}
	}

	// Use the improved example_value() method from jsonschema module
	example := schema.example_value()

	// For string types without explicit examples, customize with parameter name
	if example == '"example_value"' && schema.typ == 'string' && param_name != '' {
		return '"example_${param_name}"'
	}

	return example
}

// generate_example_call creates a formatted JSON example for method calls.
// Combines all parameter examples into a properly formatted JSON object.
fn generate_example_call(params []DocParam) string {
	if params.len == 0 {
		return '{}'
	}

	mut call_parts := []string{}
	for param in params {
		call_parts << '"${param.name}": ${param.example}'
	}

	return '{\n  ${call_parts.join(',\n  ')}\n}'
}

// generate_example_response creates a formatted JSON example for method responses.
// Wraps the result example in a standard {"result": ...} format.
fn generate_example_response(result DocParam) string {
	if result.name == '' {
		return '{"result": "success"}'
	}

	return '{"result": ${result.example}}'
}

// Create authentication documentation info
fn create_auth_info() AuthDocInfo {
	return AuthDocInfo{
		steps: [
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

// generate_jsonrpc_example_call creates a complete JSON-RPC request example
fn generate_jsonrpc_example_call(method_name string, params []DocParam) string {
	params_obj := if params.len == 0 {
		'{}'
	} else {
		mut call_parts := []string{}
		for param in params {
			call_parts << '"${param.name}": ${param.example}'
		}
		'{\n    ${call_parts.join(',\n    ')}\n  }'
	}

	return '{\n  "jsonrpc": "2.0",\n  "method": "${method_name}",\n  "params": ${params_obj},\n  "id": 1\n}'
}

// generate_curl_example_jsonrpc creates a curl command with proper JSON-RPC format
fn generate_curl_example_jsonrpc(method_name string, params []DocParam, base_url string, handler_name string) string {
	endpoint := '${base_url}/api/${handler_name}'
	jsonrpc_request := generate_jsonrpc_example_call(method_name, params)

	mut curl_cmd := 'curl -X POST ${endpoint} \\\n'
	curl_cmd += '  -H "Content-Type: application/json" \\\n'
	curl_cmd += '  -d \'${jsonrpc_request}\''

	return curl_cmd
}

// generate_curl_example creates a curl command for the given method (legacy)
pub fn generate_curl_example(method DocMethod, base_url string, handler_name string) string {
	endpoint := '${base_url}/api/${handler_name}'

	mut curl_cmd := 'curl -X POST ${endpoint} \\\n'
	curl_cmd += '  -H "Content-Type: application/json" \\\n'
	curl_cmd += '  -d \'${method.example_call}\''

	return curl_cmd
}
