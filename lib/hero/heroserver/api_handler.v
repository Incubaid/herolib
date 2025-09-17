module heroserver

import json
import veb
import freeflowuniverse.herolib.schemas.jsonrpc

@['/auth/:action']
pub fn (mut server HeroServer) auth_handler(mut ctx Context, action string) !veb.Result {
	match action {
		'register' {
			request := json.decode(RegisterRequest, ctx.req.data) or {
				return ctx.request_error('Invalid JSON format')
			}
			server.register(request.pubkey)!
			return ctx.json({
				'status': 'success'
			})
		}
		'authreq' {
			request := json.decode(AuthRequest, ctx.req.data) or {
				return ctx.request_error('Invalid JSON format')
			}
			response := server.auth_request(request.pubkey)!
			return ctx.json(response)
		}
		'auth' {
			request := json.decode(AuthSubmitRequest, ctx.req.data) or {
				return ctx.request_error('Invalid JSON format')
			}
			response := server.auth_submit(request.pubkey, request.signature)!
			return ctx.json(response)
		}
		else {
			return ctx.not_found()
		}
	}
}

@['/api/:handler_type'; post]
pub fn (mut server HeroServer) api_handler(mut ctx Context, handler_type string) veb.Result {
	// TODO: For now, skip authentication for testing
	// session_key := ctx.get_header(.authorization) or {
	// 	return ctx.request_error('Missing session key in Authorization header')
	// }.replace('Bearer ', '')

	// // Validate session
	// mut session := server.validate_session(session_key) or {
	// 	return ctx.request_error('Invalid session')
	// }

	// Get the registered handler
	mut handler := server.handlers[handler_type] or {
		return ctx.request_error('Handler not found: ${handler_type}')
	}

	// Parse JSON-RPC request
	request := jsonrpc.decode_request(ctx.req.data) or {
		return ctx.request_error('Invalid JSON-RPC request: ${err}')
	}

	// Handle the request using the OpenRPC handler
	response := handler.handle(request) or { return ctx.server_error('Handler error: ${err}') }

	// Return the JSON-RPC response
	return ctx.json(response)
}
