module jsonrpc

// Standard JSON-RPC 2.0 error codes and messages as defined in the specification
// See: https://www.jsonrpc.org/specification#error_object

// parse_error indicates that the server received invalid JSON.
// This error is returned when the server is unable to parse the request.
// Error code: -32700
pub const parse_error = RPCError{
	code:    -32700
	message: 'Parse error'
	data:    'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.'
}

// invalid_request indicates that the sent JSON is not a valid Request object.
// This error is returned when the request object doesn't conform to the JSON-RPC 2.0 specification.
// Error code: -32600
pub const invalid_request = RPCError{
	code:    -32600
	message: 'Invalid Request'
	data:    'The JSON sent is not a valid Request object.'
}

// method_not_found indicates that the requested method doesn't exist or is not available.
// This error is returned when the method specified in the request is not supported.
// Error code: -32601
pub const method_not_found = RPCError{
	code:    -32601
	message: 'Method not found'
	data:    'The method does not exist / is not available.'
}

// invalid_params indicates that the method parameters are invalid.
// This error is returned when the parameters provided to the method are incorrect or incompatible.
// Error code: -32602
pub const invalid_params = RPCError{
	code:    -32602
	message: 'Invalid params'
	data:    'Invalid method parameter(s).'
}

// internal_error indicates an internal JSON-RPC error.
// This is a generic server-side error when no more specific error is applicable.
// Error code: -32603
pub const internal_error = RPCError{
	code:    -32603
	message: 'Internal Error'
	data:    'Internal JSON-RPC error.'
}

// RPCError represents a JSON-RPC 2.0 error object as defined in the specification.
// Error objects contain a code, message, and optional data field to provide
// more information about the error that occurred.
@[params]
pub struct RPCError {
pub mut:
	// Numeric error code. Predefined codes are in the range -32768 to -32000.
	// Custom error codes should be outside this range.
	code int

	// Short description of the error
	message string

	// Additional information about the error (optional)
	data ?string
}

// new_error creates a new error response for a given request ID.
// This is a convenience function to create a Response object with an error.
//
// Parameters:
//   - id: The request ID that this error is responding to
//   - error: The RPCError object to include in the response
//
// Returns:
//   - A Response object containing the error
pub fn new_error(id int, error RPCError) Response {
	return Response{
		jsonrpc: jsonrpc_version
		error_:  error
		id:      id
	}
}

// msg returns the error message.
// This is a convenience method to access the message field.
//
// Returns:
//   - The error message string
pub fn (err RPCError) msg() string {
	return err.message
}

// code returns the error code.
// This is a convenience method to access the code field.
//
// Returns:
//   - The numeric error code
pub fn (err RPCError) code() int {
	return err.code
}

// is_empty checks if the error object is empty (uninitialized).
// An error is considered empty if its code is 0, which is not a valid JSON-RPC error code.
//
// Returns:
//   - true if the error is empty, false otherwise
pub fn (err RPCError) is_empty() bool {
	return err.code == 0
}
