module jsonrpc

import json
import x.json2
import rand

// Request represents a JSON-RPC 2.0 request object.
// It contains all the required fields according to the JSON-RPC 2.0 specification.
// See: https://www.jsonrpc.org/specification#request_object
pub struct Request {
pub mut:
	// The JSON-RPC protocol version, must be exactly "2.0"
	jsonrpc string @[required]

	// The name of the method to be invoked on the server
	method string @[required]

	// The parameters to the method, encoded as a JSON string
	// This can be omitted if the method doesn't require parameters
	params string

	// An identifier established by the client that must be included in the response
	// This is used to correlate requests with their corresponding responses
	id int @[required]
}

// new_request creates a new JSON-RPC request with the specified method and parameters.
// It automatically sets the JSON-RPC version to the current version and generates a unique ID.
//
// Parameters:
//   - method: The name of the method to invoke on the server
//   - params: The parameters to the method, encoded as a JSON string
//
// Returns:
//   - A fully initialized Request object
pub fn new_request(method string, params string) Request {
	return Request{
		jsonrpc: jsonrpc_version
		method:  method
		params:  params
		id:      rand.int_in_range(1, 1000000) or { panic('Failed to generate unique ID') }
	}
}

// decode_request parses a JSON string into a Request object.
//
// Parameters:
//   - data: A JSON string representing a JSON-RPC request
//
// Returns:
//   - A Request object or an error if parsing fails
pub fn decode_request(data string) !Request {
	mut r2 := json2.decode[json2.Any](data)!
	mut r3 := r2.as_map()
	a := (r3['jsonrpc'] or { return error('jsonrpc field not found') }).str()
	b := (r3['method'] or { return error('method field not found') }).str()
	c := (r3['params'] or { return error('params field not found') }).str()
	d := (r3['id'] or { return error('id field not found') }).int()
	mut r4 := Request{
		jsonrpc: a
		method:  b
		params:  c
		id:      d
	}
	return r4
}

// encode serializes the Request object into a JSON string.
//
// Returns:
//   - A JSON string representation of the Request
pub fn (req Request) encode() string {
	return json2.encode(req, prettify: true)
}

// validate checks if the Request object contains all required fields
// according to the JSON-RPC 2.0 specification.
//
// Returns:
//   - An error if validation fails, otherwise nothing
pub fn (req Request) validate() ! {
	if req.jsonrpc == '' {
		return error('request jsonrpc version not specified')
	} else if req.id == -1 {
		return error('request id is empty')
	} else if req.method == '' {
		return error('request method is empty')
	}
}

// RequestGeneric is a type-safe version of the Request struct that allows
// for strongly-typed parameters using generics.
// This provides compile-time type safety for request parameters.
pub struct RequestGeneric[T] {
pub mut:
	// The JSON-RPC protocol version, must be exactly "2.0"
	jsonrpc string @[required]

	// The name of the method to be invoked on the server
	method string @[required]

	// The parameters to the method, with a specific type T
	params T

	// An identifier established by the client
	id int @[required]
}

// new_request_generic creates a new generic JSON-RPC request with strongly-typed parameters.
// It automatically sets the JSON-RPC version and generates a unique ID.
//
// Parameters:
//   - method: The name of the method to invoke on the server
//   - params: The parameters to the method, of type T
//
// Returns:
//   - A fully initialized RequestGeneric object with parameters of type T
pub fn new_request_generic[T](method string, params T) RequestGeneric[T] {
	return RequestGeneric[T]{
		jsonrpc: jsonrpc_version
		method:  method
		params:  params
		id:      rand.int_in_range(1, 1000000000) or { panic('Failed to generate unique ID') }
	}
}

// decode_request_id extracts just the ID field from a JSON-RPC request string.
// This is useful when you only need the ID without parsing the entire request.
//
// Parameters:
//   - data: A JSON string representing a JSON-RPC request
//
// Returns:
//   - The ID as a string, or an error if the ID field is missing
pub fn decode_request_id(data string) !int {
	data_any := json2.decode[json2.Any](data)!
	data_map := data_any.as_map()
	id_any := data_map['id'] or { return error('ID field not found') }
	return id_any.int()
}

// decode_request_method extracts just the method field from a JSON-RPC request string.
// This is useful when you need to determine the method without parsing the entire request.
//
// Parameters:
//   - data: A JSON string representing a JSON-RPC request
//
// Returns:
//   - The method name as a string, or an error if the method field is missing
pub fn decode_request_method(data string) !string {
	data_any := json2.decode[json2.Any](data)!
	data_map := data_any.as_map()
	method_any := data_map['method'] or { return error('Method field not found') }
	return method_any.str()
}

// decode_request_generic parses a JSON string into a RequestGeneric object with parameters of type T.
//
// Parameters:
//   - data: A JSON string representing a JSON-RPC request
//
// Returns:
//   - A RequestGeneric object with parameters of type T, or an error if parsing fails
pub fn decode_request_generic[T](data string) !RequestGeneric[T] {
	return json.decode(RequestGeneric[T], data)!
}

// encode serializes the RequestGeneric object into a JSON string.
//
// Returns:
//   - A JSON string representation of the RequestGeneric object
pub fn (req RequestGeneric[T]) encode[T]() string {
	return json2.encode(req)
}
