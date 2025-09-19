module heromodels

import freeflowuniverse.herolib.hero.heroserver
import os

// Start heromodels server using heroserver
@[params]
pub struct ServerArgs {
pub mut:
	port            int    = 8080
	host            string = 'localhost'
	auth_enabled    bool   = true
	cors_enabled    bool   = true
	reset           bool
	allowed_origins []string = ['*'] // Default allows all origins
	name            string
}

pub fn server_start(args ServerArgs) ! {
	// Create a new heroserver instance
	mut server := heroserver.new(
		port:            args.port
		host:            args.host
		auth_enabled:    args.auth_enabled
		cors_enabled:    args.cors_enabled
		allowed_origins: args.allowed_origins
	)!

	mut f := get(args.name)!
	server.register_handler('heromodels', f.rpc_handler)!

	// Start the server
	server.start()!
}
