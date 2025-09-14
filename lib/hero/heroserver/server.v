module heroserver

import veb
import freeflowuniverse.herolib.schemas.jsonrpc

pub struct HeroServer {
pub mut:
	config           ServerConfig
	auth_manager     &AuthManager
	handler_registry &HandlerRegistry
}

pub struct Context {
	veb.Context
}

// Start the server
pub fn (mut s HeroServer) start() ! {
	veb.run[HeroServer, Context](mut s, s.config.port)
}

// Authentication endpoints
@['/register'; post]
pub fn (mut s HeroServer) register(mut ctx Context) veb.Result {
	// Implementation for pubkey registration
	return ctx.text('not implemented')
}

@['/authreq'; post]
pub fn (mut s HeroServer) authreq(mut ctx Context) veb.Result {
	// Implementation for authentication request
	return ctx.text('not implemented')
}

@['/auth'; post]
pub fn (mut s HeroServer) auth(mut ctx Context) veb.Result {
	// Implementation for authentication verification
	return ctx.text('not implemented')
}

// API endpoints
@['/api/:handler_type'; post]
pub fn (mut s HeroServer) api(mut ctx Context) veb.Result {
	handler_type := ctx.params['handler_type'] or {
		return ctx.request_error('handler_type not found in params')
	}

	// Validate session
	session_key := ctx.req.header.get('Authorization') or { '' }
	if !s.auth_manager.validate_session(session_key) {
		return ctx.request_error('Invalid session')
	}

	// Get handler and process request
	mut handler := s.handler_registry.get(handler_type) or { return ctx.not_found() }

	request := jsonrpc.decode_request(ctx.req.data) or {
		return ctx.request_error('Invalid JSON-RPC request')
	}

	response := handler.handle(request) or { return ctx.server_error('Handler error') }

	return ctx.json(response)
}

// Documentation endpoints
@['/doc/:handler_type'; get]
pub fn (mut s HeroServer) doc(mut ctx Context) veb.Result {
	handler_type := ctx.params['handler_type'] or {
		return ctx.request_error('handler_type not found in params')
	}

	handler := s.handler_registry.get(handler_type) or { return ctx.not_found() }

	doc_html := s.generate_documentation(handler_type, handler) or {
		return ctx.server_error('Documentation generation failed')
	}

	return ctx.html(doc_html)
}
