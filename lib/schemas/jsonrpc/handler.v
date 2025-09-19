module jsonrpc

import x.json2 as json

// This file implements a JSON-RPC 2.0 handler
// It provides functionality to register procedure handlers and process incoming JSON-RPC requests.

// Handler is a JSON-RPC request handler that maps method names to their corresponding procedure handlers.
// It can be used with a WebSocket server to handle incoming JSON-RPC requests.
@[heap]
pub struct Handler {
pub mut:
	// A map where keys are method names and values are the corresponding procedure handler functions
	procedures       map[string]ProcedureHandler
	procedures_group map[string]ProcedureHandlerGroup
	servercontext    map[string]string
}

// ProcedureHandler is a function type that processes a JSON-RPC request payload and returns a response.
// The function should:
// 1. Decode the payload to extract parameters
// 2. Execute the procedure with the extracted parameters
// 3. Return the result as a JSON-encoded string
// If an error occurs during any of these steps, it should be returned.
pub type ProcedureHandler = fn (request Request) !Response

pub type ProcedureHandlerGroup = fn (rpcid int, servercontext map[string]string, actorname string, methodname string, params string) !Response

// new_handler creates a new JSON-RPC handler with the specified procedure handlers.
//
// Parameters:
//   - handler: A Handler struct with the procedures field initialized
//
// Returns:
//   - A pointer to a new Handler instance or an error if creation fails
pub fn new_handler(handler Handler) !&Handler {
	return &Handler{
		...handler
	}
}

// register_procedure registers a new procedure handler for the specified method.
//
// Parameters:
//   - method: The name of the method to register
//   - procedure: The procedure handler function to register
pub fn (mut handler Handler) register_procedure[T, U](method string, function fn (T) !U) {
	procedure := Procedure[T, U]{
		function: function
		method:   method
	}
	handler.procedures[procedure.method] = procedure.handle
}

// register_procedure registers a new procedure handler for the specified method.
//
// Parameters:
//   - method: The name of the method to register
//   - procedure: The procedure handler function to register
pub fn (mut handler Handler) register_procedure_void[T](method string, function fn (T) !) {
	procedure := ProcedureVoid[T]{
		function: function
		method:   method
	}
	handler.procedures[procedure.method] = procedure.handle
}

// // register_procedure registers a new procedure handler for the specified method.
// //
// // Parameters:
// //   - method: The name of the method to register
// //   - procedure: The procedure handler function to register
// pub fn (mut handler Handler) register_procedure(method string, procedure ProcedureHandler) {
// 	handler.procedures[method] = procedure
// }

// register_procedure registers a new procedure handler for the specified method.
//
// Parameters:
//   - method: The name of the method to register
//   - procedure: The procedure handler group function to register
pub fn (mut handler Handler) register_api_handler(groupname string, procedure_group ProcedureHandlerGroup) {
	handler.procedures_group[groupname] = procedure_group
}

pub struct Procedure[T, U] {
pub mut:
	method   string
	function fn (T) !U
}

pub struct ProcedureVoid[T] {
pub mut:
	method   string
	function fn (T) !
}

pub fn (pw Procedure[T, U]) handle(request Request) !Response {
	payload := decode_payload[T](request.params) or {
		RPCError{
			code:    -32603
			message: 'Invalid request params on rpc request.'
			data:    '${request.params}'
		}
	}
	result := pw.function(payload) or {
		return RPCError{
			code:    -32603
			message: 'Error in function on rpc request.'
			data:    '${request}\n${err}'
		}
	}
	return new_response(request.id, '')
}

pub fn (pw ProcedureVoid[T]) handle(request Request) !Response {
	payload := decode_payload[T](request.params) or { return invalid_params }
	result := pw.function(payload) or {
		return RPCError{
			code:    -32603
			message: 'Error in function on rpc request.'
			data:    '${request}\n${err}'
		}
	}
	return new_response(request.id, 'null')
}

pub fn decode_payload[T](payload string) !T {
	$if T is string {
		return payload
	} $else $if T is int {
		return payload.int()
	} $else $if T is u32 {
		return payload.u32()
	} $else $if T is bool {
		return payload.bool()
	} $else {
		return json.decode[T](payload) or { return error('Failed to decode payload: ${err}') }
	}
	panic('Unsupported type: ${T.name}')
}

fn error_to_jsonrpc(err IError) !RPCError {
	return error('Internal error: ${err.msg()}')
}

// handler is a callback function compatible with the WebSocket server's message handler interface.
// It processes an incoming WebSocket message as a JSON-RPC request and returns the response.
//
// Parameters:
//   - client: The WebSocket client that sent the message
//   - message: The JSON-RPC request message as a string
//
// Returns:
//   - The JSON-RPC response as a string
// Note: This method panics if an error occurs during handling
// pub fn (handler Handler) handle_message(client &websocket.Client, message string) string {
// 	req := decode_request(message) or {
// 		return invalid_request }
// 	resp := handler.handle(req) or { panic(err) }
// 	return resp.encode()
// }

// handle processes a JSON-RPC request message and invokes the appropriate procedure handler.
// If the requested method is not found, it returns a method_not_found error response.
//
// Parameters:
//   - message: The JSON-RPC request message as a string
//
// Returns:
//   - The JSON-RPC response as a string, or an error if processing fails
pub fn (handler Handler) handle(request Request) !Response {
	if request.method.contains('.') {
		parts := request.method.split('.')
		mut groupname := ''
		mut actorname := ''
		mut methodname := ''
		if parts.len == 2 {
			groupname = 'default'
			actorname = parts[0]
			methodname = parts[1]
		} else if parts.len == 3 {
			groupname = parts[0]
			actorname = parts[1]
			methodname = parts[2]
		} else {
			return new_error(request.id, invalid_params)
		}
		procedure_group := handler.procedures_group[groupname] or {
			return new_error(request.id, RPCError{
				code:    -32602
				message: 'Could not find procedure group ${groupname} in function on rpc request.'
				data:    '${request}'
			})
		}
		return procedure_group(request.id, handler.servercontext, actorname, methodname,
			request.params) or {
			// Return proper JSON-RPC error instead of panicking
			return new_error(request.id, RPCError{
				code:    -32603
				message: 'Error in function on rpc request.'
				data:    '${request}\n${err}'
			})
		}
	}

	procedure_func := handler.procedures[request.method] or {
		return new_error(request.id, method_not_found)
	}

	// Execute the procedure handler with the request payload
	return procedure_func(request) or {
		// Return proper JSON-RPC error instead of panicking
		return new_error(request.id, RPCError{
			code:    -32603
			message: 'Error in function on rpc request.'
			data:    '${request}\n${err}'
		})
	}
}
