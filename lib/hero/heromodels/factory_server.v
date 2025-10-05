module heromodels

import freeflowuniverse.herolib.hero.heroserver
import freeflowuniverse.herolib.crypt.herocrypt

// Start heromodels server using heroserver
@[params]
pub struct ServerArgs {
pub mut:
	name            string
	port            int      = 8080        // Port to bind the server to
	host            string   = 'localhost' // Host to bind the server to
	auth_enabled    bool     = true        // Whether to enable authentication
	cors_enabled    bool     = true        // Whether to enable CORS
	reset           bool     = !true       // Whether to reset the database
	allowed_origins []string = ['*']       // Default allows all origins
	name            string   = 'default'   // Name of the heromodels factory
	crypto_client   ?&herocrypt.HeroCrypt // Optional crypto client, will create default if not provided
	redis_host      string = 'localhost' // redis host for heromodels db
	redis_port      int    = 6379        // redis port for heromodels db
}

pub fn server_start(args_ ServerArgs) ! {
	mut args := args_

	if args.crypto_client == none {
		// Configure Redis connection for crypto database
		args.crypto_client = herocrypt.new('${args.redis_host}:${args.redis_port}')!
	}
	// Create a new heroserver instance
	mut server := heroserver.new(
		port:            args.port
		host:            args.host
		auth_enabled:    args.auth_enabled
		cors_enabled:    args.cors_enabled
		allowed_origins: args.allowed_origins
		crypto_client:   args.crypto_client
	)!

	mut f := get(args.name)!
	server.register_handler('heromodels', f.rpc_handler)!
	server.start()!
}
