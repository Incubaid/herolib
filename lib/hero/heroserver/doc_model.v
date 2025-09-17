module heroserver

import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.schemas.jsonschema

// DocSpec is the main object passed to the documentation template.
pub struct DocSpec {
pub mut:
	info          openrpc.Info
	methods       []DocMethod
	objects       []DocObject
	auth_info     AuthDocInfo
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

// Converts an OpenRPC spec to a documentation-friendly spec
pub fn doc_spec_from_openrpc(openrpc_spec openrpc.OpenRPC, handler_type string) DocSpec {
	mut doc_spec := DocSpec{
		info: openrpc_spec.info
		auth_info: create_auth_info()
	}
	
	mut methods_by_obj := map[string][]DocMethod{}
	
	for method in openrpc_spec.methods {
		mut doc_method := DocMethod{
			name:        method.name
			summary:     method.summary
			description: method.description
			endpoint_url: '/api/${handler_type}/${method.name}'
		}
		
		// Process parameters
		for param_ref in method.params {
			if param_ref is openrpc.ContentDescriptor {
				param := param_ref as openrpc.ContentDescriptor
				doc_param := DocParam{
					name: param.name
					description: param.description
					type_info: schema_to_type_string(param.schema)
					required: param.required
					example: generate_example_for_schema(param.schema)
				}
				doc_method.params << doc_param
			}
		}
		
		// Process result
		if method.result is openrpc.ContentDescriptor {
			result := method.result as openrpc.ContentDescriptor
			doc_method.result = DocParam{
				name: result.name
				description: result.description
				type_info: schema_to_type_string(result.schema)
				example: generate_example_for_schema(result.schema)
			}
		}
		
		// Generate examples
		if method.examples.len > 0 {
			example := method.examples[0]
			doc_method.example_call = generate_call_example(doc_method)
			doc_method.example_response = generate_response_example(doc_method)
		} else {
			doc_method.example_call = generate_call_example(doc_method)
			doc_method.example_response = generate_response_example(doc_method)
		}
		
		doc_spec.methods << doc_method
		
		// Group by object
		parts := method.name.split('.')
		if parts.len > 1 {
			obj_name := parts[0]
			if obj_name !in methods_by_obj {
				methods_by_obj[obj_name] = []DocMethod{}
			}
			methods_by_obj[obj_name] << doc_method
		}
	}
	
	// Create doc objects
	for obj_name, methods in methods_by_obj {
		mut description := 'Operations for ${obj_name}'
		
		// Try to get description from tags
		for tag_ref in openrpc_spec.methods[0].tags {
			if tag_ref is openrpc.Tag {
				tag := tag_ref as openrpc.Tag
				if tag.name == obj_name {
					description = tag.description
					break
				}
			}
		}
		
		doc_spec.objects << DocObject{
			name: obj_name
			description: description
			methods: methods
		}
	}
	
	return doc_spec
}

// Convert schema to human-readable type string
fn schema_to_type_string(schema_ref openrpc.SchemaRef) string {
	if schema_ref is jsonschema.Schema {
		schema := schema_ref as jsonschema.Schema
		match schema.typ {
			'string' { return 'string' }
			'integer' { return 'integer' }
			'number' { return 'number' }
			'boolean' { return 'boolean' }
			'array' { 
				if items := schema.items {
					item_type := if items is jsonschema.SchemaRef {
						schema_to_type_string(items as jsonschema.SchemaRef)
					} else {
						'mixed'
					}
					return 'array of ${item_type}'
				}
				return 'array'
			}
			'object' { return 'object' }
			else { return schema.typ }
		}
	} else if schema_ref is jsonschema.Reference {
		ref := schema_ref as jsonschema.Reference
		return ref.ref.all_after_last('/')
	}
	return 'unknown'
}

// Generate example value for schema
fn generate_example_for_schema(schema_ref openrpc.SchemaRef) string {
	if schema_ref is jsonschema.Schema {
		schema := schema_ref as jsonschema.Schema
		match schema.typ {
			'string' { return '"example_string"' }
			'integer' { return '42' }
			'number' { return '3.14' }
			'boolean' { return 'true' }
			'array' { return '[]' }
			'object' { return '{}' }
			else { return '""' }
		}
	}
	return '""'
}

// Generate call example
fn generate_call_example(method DocMethod) string {
	mut params := []string{}
	for param in method.params {
		params << '"${param.name}": ${param.example}'
	}
	
	if params.len == 0 {
		return '{}'
	}
	
	return '{\n  ${params.join(',\n  ')}\n}'
}

// Generate response example
fn generate_response_example(method DocMethod) string {
	if method.result.name != '' {
		return '{\n  "result": ${method.result.example}\n}'
	}
	return '{\n  "result": "success"\n}'
}

// Create authentication documentation info
fn create_auth_info() AuthDocInfo {
	return AuthDocInfo{
		steps: [
			AuthStep{
				number: 1
				title: 'Register Public Key'
				method: 'POST'
				endpoint: '/auth/register'
				description: 'Register your public key with the server'
				example: '{\n  "pubkey": "your_public_key_here"\n}'
			},
			AuthStep{
				number: 2
				title: 'Request Challenge'
				method: 'POST'
				endpoint: '/auth/authreq'
				description: 'Request an authentication challenge'
				example: '{\n  "pubkey": "your_public_key_here"\n}'
			},
			AuthStep{
				number: 3
				title: 'Submit Signature'
				method: 'POST'
				endpoint: '/auth/auth'
				description: 'Sign the challenge and submit for authentication'
				example: '{\n  "pubkey": "your_public_key_here",\n  "signature": "signed_challenge"\n}'
			},
			AuthStep{
				number: 4
				title: 'Use Session Key'
				method: 'ALL'
				endpoint: '/api/{handler}/{method}'
				description: 'Include session key in Authorization header for all API calls'
				example: 'Authorization: Bearer {session_key}'
			}
		]
	}
}