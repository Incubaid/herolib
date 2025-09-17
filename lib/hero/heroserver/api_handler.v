module heroserver

import json
import veb

@['/auth/:action']
pub fn (mut server HeroServer) auth_handler(mut ctx Context, action string) !veb.Result {
	match action {
		'register' {
			request := json.decode(RegisterRequest, ctx.req.data) or {
				return ctx.request_error('Invalid JSON format')
			}
			server.register(request.pubkey)!
			return ctx.json({'status': 'success'})
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

@['/api/:handler_type/:method_name']
pub fn (mut server HeroServer) api_handler(mut ctx Context, handler_type string, method_name string) veb.Result {
	session_key := ctx.get_header(.authorization) or {
		return ctx.request_error('Missing session key in Authorization header')
	}.replace('Bearer ', '')

	// Validate session
	mut session := server.validate_session(session_key) or {
		return ctx.request_error('Invalid session')
	}

	// For now, simplified response
	return ctx.json({'result': 'success'})
}