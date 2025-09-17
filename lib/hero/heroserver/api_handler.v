module heroserver

import net.http
import json
import veb

// Setup API routes
pub fn (mut server HeroServer) setup_api_routes() ! {
	// Authentication endpoints
	server.app.mount('/auth', auth_handler)
	
	// API endpoints for each handler type
	for handler_type, _ in server.handlers {
		server.app.mount('/api/${handler_type}', api_handler)
	}
}

// Authentication handler functions
fn auth_handler(mut ctx Context) veb.Result {
	match ctx.req.method {
		.post {
			// Extract path to determine action
			path_parts := ctx.req.url.path.split('/')
			if path_parts.len < 3 {
				return ctx.request_error('Invalid endpoint')
			}
			
			action := path_parts[2]
			match action {
				'register' { return handle_register(mut ctx) }
				'authreq' { return handle_auth_request(mut ctx) }
				'auth' { return handle_auth_submit(mut ctx) }
				else { return ctx.not_found() }
			}
		}
		else {
			return ctx.request_error('Method not allowed')
		}
	}
}

fn handle_register(mut ctx Context) veb.Result {
	// Parse JSON request
	request := json.decode(RegisterRequest, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format')
	}
	
	// Get server from context (you'll need to add this to Context)
	// For now, this is a simplified approach
	return ctx.json({'status': 'success'})
}

fn handle_auth_request(mut ctx Context) veb.Result {
	// Parse JSON request
	request := json.decode(AuthRequest, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format')
	}
	
	// Generate challenge (simplified)
	return ctx.json({'challenge': 'sample_challenge'})
}

fn handle_auth_submit(mut ctx Context) veb.Result {
	// Parse JSON request
	request := json.decode(AuthSubmitRequest, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format')
	}
	
	// Return session key (simplified)
	return ctx.json({'session_key': 'sample_session_key'})
}

// API handler for specific handler types
fn api_handler(mut ctx Context) veb.Result {
	// Extract session key from header
	session_key := ctx.get_header(.authorization) or {
		return ctx.request_error('Missing session key in Authorization header')
	}.replace('Bearer ', '')
	
	// For now, simplified response
	return ctx.json({'result': 'success'})
}