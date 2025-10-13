module openrpc

import incubaid.herolib.schemas.jsonrpc

// The openrpc handler is a wrapper around a jsonrpc handler
pub struct Handler {
	jsonrpc.Handler
pub:
	specification OpenRPC @[required] // The OpenRPC specification
}

// pub interface IHandler {
// mut:
// 	handle(jsonrpc.Request) !jsonrpc.Response // Custom handler for other methods
// }

// Handle a JSON-RPC request and return a response
pub fn (mut h Handler) handle(req jsonrpc.Request) !jsonrpc.Response {
	// Validate the incoming request
	req.validate() or { return jsonrpc.new_error_response(req.id, jsonrpc.invalid_request) }

	// Check if the method exists
	if req.method == 'rpc.discover' {
		// Handle the rpc.discover method
		spec_json := h.specification.encode()!
		return jsonrpc.new_response(req.id, spec_json)
	}

	// Validate the method exists in the specification
	// TODO: implement once auto add registered methods to spec
	// if req.method !in h.specification.methods.map(it.name) {
	// 	println("Method not found: " + req.method)
	// 	return jsonrpc.new_error_response(req.id, jsonrpc.method_not_found)
	// }

	// Forward the request to the custom handler
	return h.Handler.handle(req) or { panic(err) }
}
