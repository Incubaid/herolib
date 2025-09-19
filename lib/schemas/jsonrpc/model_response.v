module jsonrpc

import x.json2
import json

// The JSON-RPC version used for all requests and responses according to the specification.
const jsonrpc_version = '2.0'

// Response represents a JSON-RPC 2.0 response object.
// According to the specification, a response must contain either a result or an error, but not both.
// See: https://www.jsonrpc.org/specification#response_object
pub struct Response {
pub:
	// The JSON-RPC protocol version, must be exactly "2.0"
	jsonrpc string @[required]

	// The result of the method invocation (only present if the call was successful)
	result ?string

	// Error object if the request failed (only present if the call failed)
	error_ ?RPCError @[json: 'error']

	// Must match the id of the request that generated this response
	id int @[required]
}

// new_response creates a successful JSON-RPC response with the given result.
//
// Parameters:
//   - id: The ID from the request that this response is answering
//   - result: The result of the method call, encoded as a JSON string
//
// Returns:
//   - A Response object containing the result
pub fn new_response(id int, result string) Response {
	return Response{
		jsonrpc: jsonrpc_version
		result:  result
		id:      id
	}
}

pub fn new_response_true(id int) Response {
	return Response{
		jsonrpc: jsonrpc_version
		result:  'true'
		id:      id
	}
}

pub fn new_response_ok(id int) Response {
	return Response{
		jsonrpc: jsonrpc_version
		result:  ''
		id:      id
	}
}

pub fn new_response_false(id int) Response {
	return Response{
		jsonrpc: jsonrpc_version
		result:  'false'
		id:      id
	}
}

pub fn new_response_int(id int, result int) Response {
	return Response{
		jsonrpc: jsonrpc_version
		result:  result.str()
		id:      id
	}
}

pub fn new_response_u32(id int, result u32) Response {
	return Response{
		jsonrpc: jsonrpc_version
		result:  result.str()
		id:      id
	}
}

// new_error_response creates an error JSON-RPC response with the given error object.
//
// Parameters:
//   - id: The ID from the request that this response is answering
//   - error: The error that occurred during the method call
//
// Returns:
//   - A Response object containing the error
pub fn new_error_response(id int, error RPCError) Response {
	return Response{
		jsonrpc: jsonrpc_version
		error_:  error
		id:      id
	}
}




// decode_response parses a JSON string into a Response object.
// This function handles the complex validation rules for JSON-RPC responses.
//
// Parameters:
//   - data: A JSON string representing a JSON-RPC response
//
// Returns:
//   - A Response object or an error if parsing fails or the response is invalid
pub fn decode_response(data string) !Response {
	raw := json2.raw_decode(data) or {
		return error('Failed to decode JSONRPC response ${data}\n${err}')
	}
	raw_map := raw.as_map()

	// Validate that the response contains either result or error, but not both or neither
	if 'error' !in raw_map.keys() && 'result' !in raw_map.keys() {
		print_backtrace()
		return error('Invalid JSONRPC response, no error and result found.')
	} else if 'error' in raw_map.keys() && 'result' in raw_map.keys() {
		print_backtrace()
		return error('Invalid JSONRPC response, both error and result found.')
	}

	// Handle error responses
	if err := raw_map['error'] {
		id_any := raw_map['id'] or { return error('Invalid JSONRPC response, no ID Field found') }
		return Response{
			id:      id_any.int()
			jsonrpc: jsonrpc_version
			error_:  json2.decode[RPCError](err.str())!
		}
	}

	// Handle successful responses
	return Response{
		id:      raw_map['id'] or {
			print_backtrace()
			return error('Invalid JSONRPC response, no ID Field found')
		}.int()
		jsonrpc: jsonrpc_version
		result:  raw_map['result']!.str()
	}
}

// encode serializes the Response object into a JSON string.
//
// Returns:
//   - A JSON string representation of the Response
pub fn (resp Response) encode() string {
	// Payload is already json string
	if resp.error_ != none {
		return '{"jsonrpc":"2.0","id":${resp.id},"error":${json2.encode(resp.error_)}}'
	} else if resp.result != none {
		return '{"jsonrpc":"2.0","id":${resp.id},"result":${resp.result}}'
	}
	return '{"jsonrpc":"2.0","id":${resp.id}}'
}

// validate checks that the Response object follows the JSON-RPC 2.0 specification.
// A valid response must not contain both result and error.
//
// Returns:
//   - An error if validation fails, otherwise nothing
pub fn (resp Response) validate() ! {
	if resp.error_ != none && resp.result != none {
		return error('Response contains both error and result.\n- Error: ${resp.error_.str()}\n- Result: ${resp.result}')
	}
	if resp.error_ == none && resp.result == none {
		return error('Response contains neither error nor result.')
	}
}

// is_error checks if the response contains an error.
//
// Returns:
//   - true if the response contains an error, false otherwise
pub fn (resp Response) is_error() bool {
	return resp.error_ != none
}

// is_result checks if the response contains a result.
//
// Returns:
//   - true if the response contains a result, false otherwise
pub fn (resp Response) is_result() bool {
	return resp.result != none
}

// error returns the error object if present in the response.
//
// Returns:
//   - The error object if present, or none if no error is present
pub fn (resp Response) error() ?RPCError {
	if err := resp.error_ {
		return err
	}
	return none
}

// result returns the result string if no error is present.
// If an error is present, it returns the error instead.
//
// Returns:
//   - The result string or an error if the response contains an error
pub fn (resp Response) result() !string {
	if err := resp.error() {
		return err
	}
	// Ensure no error is present
	return resp.result or { '' }
}

// ResponseGeneric is a type-safe version of the Response struct that allows
// for strongly-typed results using generics.
// This provides compile-time type safety for response results.
pub struct ResponseGeneric[D] {
pub mut:
	// The JSON-RPC protocol version, must be exactly "2.0"
	jsonrpc string @[required]

	// The result of the method invocation with a specific type D
	result ?D

	// Error object if the request failed
	error_ ?RPCError @[json: 'error']

	// Must match the id of the request that generated this response
	id int @[required]
}

// new_response_generic creates a successful generic JSON-RPC response with a strongly-typed result.
//
// Parameters:
//   - id: The ID from the request that this response is answering
//   - result: The result of the method call, of type D
//
// Returns:
//   - A ResponseGeneric object with result of type D
pub fn new_response_generic[D](id int, result D) ResponseGeneric[D] {
	return ResponseGeneric[D]{
		jsonrpc: jsonrpc_version
		result:  result
		id:      id
	}
}

// decode_response_generic parses a JSON string into a ResponseGeneric object with result of type D.
// This function handles the complex validation rules for JSON-RPC responses.
//
// Parameters:
//   - data: A JSON string representing a JSON-RPC response
//
// Returns:
//   - A ResponseGeneric object with result of type D, or an error if parsing fails
pub fn decode_response_generic[D](data string) !ResponseGeneric[D] {
	raw := json2.raw_decode(data)!
	raw_map := raw.as_map()

	// Validate that the response contains either result or error, but not both or neither
	if 'error' !in raw_map.keys() && 'result' !in raw_map.keys() {
		print_backtrace()
		return error('Invalid JSONRPC response, no error and result found.')
	} else if 'error' in raw_map.keys() && 'result' in raw_map.keys() {
		print_backtrace()
		return error('Invalid JSONRPC response, both error and result found.')
	}

	// Handle error responses
	if err := raw_map['error'] {
		return ResponseGeneric[D]{
			id:      raw_map['id'] or {
				print_backtrace()
				return error('Invalid JSONRPC response, no ID Field found')
			}.int()
			jsonrpc: jsonrpc_version
			error_:  json2.decode[RPCError](err.str())!
		}
	}

	// Handle successful responses
	resp := json.decode(ResponseGeneric[D], data)!
	return ResponseGeneric[D]{
		id:      raw_map['id'] or {
			print_backtrace()
			return error('Invalid JSONRPC response, no ID Field found')
		}.int()
		jsonrpc: jsonrpc_version
		result:  resp.result
	}
}

// encode serializes the ResponseGeneric object into a JSON string.
//
// Returns:
//   - A JSON string representation of the ResponseGeneric object
pub fn (resp ResponseGeneric[D]) encode() string {
	return json2.encode(resp)
}

// validate checks that the ResponseGeneric object follows the JSON-RPC 2.0 specification.
// A valid response must not contain both result and error.
//
// Returns:
//   - An error if validation fails, otherwise nothing
pub fn (resp ResponseGeneric[D]) validate() ! {
	if resp.is_error() && resp.is_result() {
		print_backtrace()
		return error('Response contains both error and result.\n- Error: ${resp.error.str()}\n- Result: ${resp.result}')
	}
}

// is_error checks if the response contains an error.
//
// Returns:
//   - true if the response contains an error, false otherwise
pub fn (resp ResponseGeneric[D]) is_error() bool {
	return resp.error_ != none
}

// is_result checks if the response contains a result.
//
// Returns:
//   - true if the response contains a result, false otherwise
pub fn (resp ResponseGeneric[D]) is_result() bool {
	return resp.result != none
}

// error returns the error object if present in the generic response.
//
// Returns:
//   - The error object if present, or none if no error is present
pub fn (resp ResponseGeneric[D]) error() ?RPCError {
	return resp.error_?
}

// result returns the result of type D if no error is present.
// If an error is present, it returns the error instead.
//
// Returns:
//   - The result of type D or an error if the response contains an error
pub fn (resp ResponseGeneric[D]) result() !D {
	if err := resp.error() {
		return err
	}
	// Ensure no error is present
	return resp.result or { D{} }
}
