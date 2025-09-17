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
	
	// Simplified implementation for now
	for method in openrpc_spec.methods {
		doc_method := DocMethod{
			name: method.name
			summary: method.summary
			description: method.description
			endpoint_url: '/api/${handler_type}/${method.name}'
			example_call: '{}'
			example_response: '{"result": "success"}'
		}
		doc_spec.methods << doc_method
	}
	
	return doc_spec
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