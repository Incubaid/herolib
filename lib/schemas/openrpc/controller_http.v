module openrpc

import veb
import freeflowuniverse.herolib.schemas.jsonrpc

// Main controller for handling RPC requests
pub struct HTTPController {
	Handler // Handles JSON-RPC requests
	// pub mut:
	// handler       Handler @[required]
}

pub struct Context {
	veb.Context
}

// Creates a new HTTPController instance
pub fn new_http_controller(c HTTPController) &HTTPController {
	return &HTTPController{
		...c
		Handler: c.Handler
	}
}

// Parameters for running the server
@[params]
pub struct RunParams {
pub:
	port int = 8080 // Default to port 8080
}

// Starts the server
pub fn (mut c HTTPController) run(params RunParams) {
	veb.run[HTTPController, Context](mut c, 8080)
}

// Handles POST requests at the index endpoint
@[post]
pub fn (mut c HTTPController) index(mut ctx Context) veb.Result {
	// Decode JSONRPC Request from POST data
	request := jsonrpc.decode_request(ctx.req.data) or {
		return ctx.server_error('Failed to decode JSONRPC Request ${err.msg()}')
	}

	// Process the JSONRPC request with the OpenRPC handler
	response := c.handle(request) or {
		return ctx.server_error('Handler error: ${err.msg()}')
	}

	// Encode and return the handler's JSONRPC Response
	return ctx.json(response)
}
