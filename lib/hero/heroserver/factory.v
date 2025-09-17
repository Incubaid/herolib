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
	
	// Create VEB app
	mut app := veb.new[HeroServer, Context]()
	
	mut server := &HeroServer{
		port: config.port
		host: config.host
		crypto_client: crypto_client
		sessions: map[string]Session{}
		handlers: map[string]&openrpc.Handler{}
		app: app
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
	// Setup routes
	server.setup_routes()!
	
	// Start VEB server
	veb.run[HeroServer, Context](mut server, 
		host: server.host, 
		port: server.port
	)!
}

// Context struct for VEB
pub struct Context {
	veb.Context
}

// Add to HeroServer struct
pub fn (mut server HeroServer) setup_routes() ! {
    // Setup authentication routes
    server.setup_api_routes()!
    
    // Setup documentation routes
    server.setup_doc_routes()!
}