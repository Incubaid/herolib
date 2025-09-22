module heroserver

import freeflowuniverse.herolib.crypt.herocrypt
import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.logger
import freeflowuniverse.herolib.osal.core as osal
import time
import veb

// Create a new HeroServer instance
pub fn new(config HeroServerConfig) !&HeroServer {
	// Check if the port is available
	osal.port_check_available(config.port) or {
		return error('Port ${config.port} is already in use')
	}

	// Initialize crypto client
	crypto_client := if c := config.crypto_client {
		c
	} else {
		herocrypt.new_default()!
	}

	// Create logger with configurable output
	mut server_logger := logger.new(
		path:           config.log_path
		console_output: config.console_output
	) or { return error('Failed to create logger: ${err}') }

	mut server := &HeroServer{
		port:            config.port
		host:            config.host
		crypto_client:   crypto_client
		sessions:        map[string]Session{}
		handlers:        map[string]&openrpc.Handler{}
		challenges:      map[string]AuthChallenge{}
		auth_enabled:    config.auth_enabled
		cors_enabled:    config.cors_enabled
		allowed_origins: config.allowed_origins.clone()
		logger:          server_logger
		start_time:      time.now().unix()
	}
	return server
}

// Register an OpenRPC handler
pub fn (mut server HeroServer) register_handler(handler_type string, handler &openrpc.Handler) ! {
	server.handlers[handler_type] = handler
	console.print_header('Registered handler: ${handler_type}')
}

// Start the server
pub fn (mut server HeroServer) start() ! {
	// Print server info
	if server.cors_enabled {
		console.print_item('CORS enabled for origins: ${server.allowed_origins}')
	}

	// Start VEB server
	console.print_item('Server starting on http://${server.host}:${server.port}')
	console.print_item('HTML Homepage: http://${server.host}:${server.port}/')
	console.print_item('JSON Info: http://${server.host}:${server.port}/json/{handler_name}')
	console.print_item('Documentation: http://${server.host}:${server.port}/doc/{handler_name}')
	console.print_item('Markdown Docs: http://${server.host}:${server.port}/md/{handler_name}')
	console.print_item('API Endpoint: http://${server.host}:${server.port}/api/{handler_name}')

	veb.run[HeroServer, Context](mut server, server.port)
}
