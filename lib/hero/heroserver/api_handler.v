module heroserver

import net.http
import json
import veb

// Setup API routes
pub fn (mut server HeroServer) setup_api_routes() ! {
	// Authentication endpoints
	server.app.register_controller[AuthController, Context]('/auth', mut &AuthController{server: server})!
	
	// API endpoints for each handler type
	for handler_type, _ in server.handlers {
		controller := &APIController{
			server: server
			handler_type: handler_type
		}
		server.app.register_controller[APIController, Context]('/api/${handler_type}', mut controller)!
	}
}

// Authentication controller
pub struct AuthController {
mut:
	server &HeroServer
}

@[post; '/register']
pub fn (mut controller AuthController) register(mut ctx Context) veb.Result {
	// Parse JSON request
	request := json.decode(RegisterRequest, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format')
	}
	
	// Register public key
	controller.server.register(request.pubkey) or {
		return ctx.request_error('Registration failed: ${err}')
	}
	
	return ctx.json({'status': 'success'})
}

@[post; '/authreq']
pub fn (mut controller AuthController) auth_request(mut ctx Context) veb.Result {
	// Parse JSON request
	request := json.decode(AuthRequest, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format')
	}
	
	// Generate challenge
	response := controller.server.auth_request(request.pubkey) or {
		return ctx.request_error('Auth request failed: ${err}')
	}
	
	return ctx.json(response)
}

@[post; '/auth']
pub fn (mut controller AuthController) auth_submit(mut ctx Context) veb.Result {
	// Parse JSON request
	request := json.decode(AuthSubmitRequest, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format')
	}
	
	// Verify and create session
	response := controller.server.auth_submit(request.pubkey, request.signature) or {
		return ctx.request_error('Authentication failed: ${err}')
	}
	
	return ctx.json(response)
}

// API controller for specific handler types
pub struct APIController {
mut:
	server &HeroServer
	handler_type string
}

@[post; '/:method']
pub fn (mut controller APIController) handle_api_call(mut ctx Context, method string) veb.Result {
	// Extract session key from header
	session_key := ctx.get_header(.authorization) or {
		return ctx.request_error('Missing session key in Authorization header')
	}.replace('Bearer ', '')
	
	// Validate session
	controller.server.validate_session(session_key) or {
		return ctx.server_error('Invalid or expired session: ${err}')
	}
	
	// Get handler
	handler := controller.server.handlers[controller.handler_type] or {
		return ctx.server_error('Handler not found')
	}
	
	// Parse request parameters
	params := if ctx.req.data.len > 0 {
		json.decode(map[string]string, ctx.req.data) or { map[string]string{} }
	} else {
		map[string]string{}
	}
	
	// Call handler method
	result := handler.call_method(method, params) or {
		return ctx.server_error('Method call failed: ${err}')
	}
	
	return ctx.json(result)
}