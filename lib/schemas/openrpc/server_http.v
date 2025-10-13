module openrpc

import veb
import incubaid.herolib.schemas.jsonrpc

// Main controller for handling RPC requests
pub struct HTTPController {
	Handler // Handles JSON-RPC requests
	// pub mut:
	// handler       Handler @[required]
}

pub struct Context {
	veb.Context
}

@[params]
pub struct HTTPServerParams {
pub mut:
	port int = 9944 // Default to port 9944
}

pub fn start_http_server(handler Handler, params HTTPServerParams) ! {
	mut server := HTTPController{
		Handler: handler
	}
	server.start(params)!
}

// Starts the server
pub fn (mut c HTTPController) start(params HTTPServerParams) ! {
	veb.run[HTTPController, Context](mut c, params.port)
}

// Handles POST requests at the index endpoint
@[post]
pub fn (mut c HTTPController) index(mut ctx Context) veb.Result {
	// Decode JSONRPC Request from POST data
	request := jsonrpc.decode_request(ctx.req.data) or {
		return ctx.server_error('Failed to decode JSONRPC Request ${err.msg()}')
	}

	// Process the JSONRPC request with the OpenRPC handler
	response := c.handle(request) or { return ctx.server_error('Handler error: ${err.msg()}') }

	// Encode and return the handler's JSONRPC Response
	return ctx.json(response)
}
