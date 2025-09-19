module heroserver

import json
import net.http
import veb
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.ui.console

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

@['/api/:handler_type'; options; post]
pub fn (mut server HeroServer) api_handler(mut ctx Context, handler_type string) veb.Result {
	if ctx.req.method == http.Method.options {
		if server.cors_enabled {
			origin := ctx.get_header(.origin) or { '' }
			if origin != ''
				&& (server.allowed_origins.contains('*') || server.allowed_origins.contains(origin)) {
				ctx.set_header(.access_control_allow_origin, origin)
				ctx.set_header(.access_control_allow_methods, 'GET, HEAD, PATCH, PUT, POST, DELETE, OPTIONS')
				ctx.set_header(.access_control_allow_headers, 'Content-Type, Authorization, X-Requested-With')
				ctx.set_header(.access_control_allow_credentials, 'true')
				ctx.set_header(.vary, 'Origin')
				server.log(
					message: 'CORS headers set for origin: ${origin}'
				)
			}
		}

		return ctx.text('')
	}

	// Set CORS headers for POST response
	if server.cors_enabled {
		origin := ctx.get_header(.origin) or { '' }
		if origin != ''
			&& (server.allowed_origins.contains('*') || server.allowed_origins.contains(origin)) {
			ctx.set_header(.access_control_allow_origin, origin)
			ctx.set_header(.access_control_allow_credentials, 'true')
			ctx.set_header(.vary, 'Origin')
			server.log(
				message: 'CORS headers set for API POST response, origin: ${origin}'
			)
		}
	}

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
	mut request := jsonrpc.decode_request(ctx.req.data) or {
		return ctx.request_error('Invalid JSON-RPC request: ${err}')
	}

	if request.method.count('.') == 0 {
		return ctx.request_error('Invalid method format, expected actor.method')
	} else if request.method.count('.') == 1 {
		request.method = '${handler_type.to_lower()}.${request.method}'
	} else {
		if request.method.count('.') > 1 {
			return ctx.request_error('Invalid method format, too many dots. ${ctx.req.method}')
		}
	}
	console.print_debug('Handling request: ${request.method} with params: ${request.params}')
	// $dbg;

	// Handle the request using the OpenRPC handler
	response := handler.handle(request) or { return ctx.server_error('Handler error: ${err}') }

	ctx.set_header(.content_type, 'application/json')
	return ctx.text(response.encode())
}
