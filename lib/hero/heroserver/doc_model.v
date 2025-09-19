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
	example_call     string
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

	// Convert result
	doc_result := process_result(method.result)!

	// Generate examples
	example_call := generate_example_call(doc_params)
	example_response := generate_example_response(doc_result)

	doc_method := DocMethod{
		name:             method.name
		summary:          method.summary
		description:      method.description
		params:           doc_params
		result:           doc_result
		endpoint_url:     '${config.base_url}/api/${config.handler_type}'
		example_call:     example_call
		example_response: example_response
		curl_example:     generate_curl_example_jsonrpc(method.name, doc_params, config.base_url,
			config.handler_type)
	}

	return doc_method
}

// process_parameters converts OpenRPC parameters to DocParam array
fn process_parameters(params []openrpc.ContentDescriptorRef) ![]DocParam {
	mut doc_params := []DocParam{}

	for param in params {
		if param is openrpc.ContentDescriptor {
			type_info := extract_type_from_schema(param.schema)
			example := generate_example_from_schema(param.schema, param.name)

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
		example := generate_example_from_schema(result.schema, result.name)

		doc_result = DocParam{
			name:        result.name
			description: result.description
			type_info:   type_info
			required:    false // Results are never required
			example:     example
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
