module heroserver

import freeflowuniverse.herolib.crypt.herocrypt
import freeflowuniverse.herolib.schemas.openrpc
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
		port: config.port
		host: config.host
		crypto_client: crypto_client
		sessions: map[string]Session{}
		handlers: map[string]&openrpc.Handler{}
		challenges: map[string]AuthChallenge{}
	}
	
	return server
}

// Register an OpenRPC handler
pub fn (mut server HeroServer) register_handler(handler_type string, handler &openrpc.Handler) ! {
	server.handlers[handler_type] = handler
}

// Start the server
pub fn (mut server HeroServer) start() ! {
	// Start VEB server
	veb.run[HeroServer, Context](mut server, server.port)
}

// Context struct for VEB
pub struct Context {
	veb.Context
}