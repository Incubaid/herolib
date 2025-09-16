module heroserver

import veb
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.hero.crypt
import freeflowuniverse.herolib.schemas.openrpc

pub struct ServerConfig {
pub mut:
	port        int = 8080
	auth_config AuthConfig
}

pub struct HeroServer {
pub mut:
	config           ServerConfig
	auth_manager     &AuthManager
	handler_registry &HandlerRegistry
	age_client       &crypt.AGEClient
	doc_registry     &DocRegistry
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
pub fn (mut s HeroServer) api(mut ctx Context, handler_type string) veb.Result {
	// Validate session
	session_key := ctx.get_custom_header('Authorization') or { '' }
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

// Documentation index endpoint - redirects to first available API
@['/docs'; get]
pub fn (mut s HeroServer) docs_index(mut ctx Context) veb.Result {
	// Setup documentation site if not already done
	s.setup_docs_site() or { return ctx.server_error('Documentation setup failed: ${err}') }

	// Redirect to the first available API documentation (preferably heroserver)
	if 'heroserver' in s.doc_registry.apis {
		return ctx.redirect('/docs/heroserver')
	}

	// If no heroserver, redirect to the first available API
	for name, _ in s.doc_registry.apis {
		return ctx.redirect('/docs/${name}')
	}

	// If no APIs available, show a message
	return ctx.html('<h1>No API documentation available</h1><p>No APIs have been registered yet.</p>')
}

// Documentation viewer for specific APIs
@['/docs/:api_name'; get]
pub fn (mut s HeroServer) docs_api(mut ctx Context, api_name string) veb.Result {
	// Setup documentation site if not already done
	s.setup_docs_site() or { return ctx.server_error('Documentation setup failed: ${err}') }

	// Check if the API exists
	if api_name !in s.doc_registry.apis {
		return ctx.not_found()
	}

	// Generate and return the documentation viewer
	html_content := s.generate_docs_viewer(api_name) or {
		return ctx.server_error('Failed to generate documentation: ${err}')
	}

	return ctx.html(html_content)
}

// Setup documentation site endpoint
@['/docs/setup'; post]
pub fn (mut s HeroServer) docs_setup(mut ctx Context) veb.Result {
	s.setup_docs_site() or { return ctx.server_error('Documentation setup failed: ${err}') }

	return ctx.json('{"status": "success", "message": "Documentation site setup completed", "url": "http://localhost:8080/docs"}')
}

// Register an API with both handler and documentation
pub fn (mut s HeroServer) register_api(name string, spec openrpc.OpenRPC, handler openrpc.Handler) {
	s.handler_registry.register(name, handler, spec)
	s.doc_registry.register_api(name, spec, handler)
}

// new_server creates a new HeroServer instance
pub fn new_server(config ServerConfig) !&HeroServer {
	mut auth_manager := new_auth_manager(config.auth_config)
	mut handler_registry := new_handler_registry()
	mut age_client := crypt.new_age_client(crypt.AGEClientConfig{})!
	mut doc_registry := new_doc_registry()

	// Register the core HeroServer API documentation
	doc_registry.register_core_api()

	return &HeroServer{
		config:           config
		auth_manager:     auth_manager
		handler_registry: handler_registry
		age_client:       age_client
		doc_registry:     doc_registry
	}
}
