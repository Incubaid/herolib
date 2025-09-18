module heroserver

import freeflowuniverse.herolib.crypt.herocrypt
import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.ui.console
import veb

// Create a new HeroServer instance
pub fn new(config HeroServerConfig) !&HeroServer {
	// Initialize crypto client
	mut crypto_client := if c := config.crypto_client {
		c
	} else {
		herocrypt.new_default()!
	}

	mut server := &HeroServer{
		port:          config.port
		host:          config.host
		crypto_client: crypto_client
		sessions:      map[string]Session{}
		handlers:      map[string]&openrpc.Handler{}
		challenges:    map[string]AuthChallenge{}
		auth_enabled:  config.auth_enabled
	}

	console.print_header('HeroServer created on port ${server.port}')
	return server
}

// Register an OpenRPC handler
pub fn (mut server HeroServer) register_handler(handler_type string, handler &openrpc.Handler) ! {
	server.handlers[handler_type] = handler
	console.print_header('Registered handler: ${handler_type}')
}

// Start the server
pub fn (mut server HeroServer) start() ! {
	// Start VEB server
	handler_name := server.handlers.keys()[0]
	console.print_green('Server starting on http://${server.host}:${server.port}')
	console.print_green('HTML Homepage: http://${server.host}:${server.port}/')
	console.print_green('JSON Info: http://${server.host}:${server.port}/json/${handler_name}')
	console.print_green('Documentation: http://${server.host}:${server.port}/doc/${handler_name}')
	console.print_green('Markdown Docs: http://${server.host}:${server.port}/md/${handler_name}')
	console.print_green('API Endpoint: http://${server.host}:${server.port}/api/${handler_name}')

	veb.run[HeroServer, Context](mut server, server.port)
}

// Context struct for VEB
pub struct Context {
	veb.Context
}
