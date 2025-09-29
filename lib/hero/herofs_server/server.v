module herofs_server

import veb
import freeflowuniverse.herolib.hero.herofs
import freeflowuniverse.herolib.ui.console

// FSServer is the main server struct
pub struct FSServer {
	veb.Controller
pub mut:
	fs_factory      herofs.FsFactory
	port            int
	host            string
	cors_enabled    bool
	allowed_origins []string
}

// Context struct for VEB
pub struct Context {
	veb.Context
}

// Factory args
@[params]
pub struct NewFSServerArgs {
pub mut:
	port            int      = 8080
	host            string   = 'localhost'
	cors_enabled    bool     = true
	allowed_origins []string = ['*']
}

// Create a new filesystem server
pub fn new(args NewFSServerArgs) !&FSServer {
	fs_factory := herofs.new()!

	mut server := FSServer{
		port:            args.port
		host:            args.host
		cors_enabled:    args.cors_enabled
		allowed_origins: args.allowed_origins
		fs_factory:      fs_factory
	}

	return &server
}

pub fn (mut server FSServer) start() ! {
	console.print_header('Starting HeroFS Server on ${server.host}:${server.port}')
	console.print_item('CORS enabled: ${server.cors_enabled}')
	if server.cors_enabled {
		console.print_item('Allowed origins: ${server.allowed_origins}')
	}
	console.print_item('Available endpoints:')
	console.print_item('  Health: GET /health')
	console.print_item('  API Info: GET /api')
	console.print_item('  Filesystems: /api/fs')
	console.print_item('  Directories: /api/dirs')
	console.print_item('  Files: /api/files')
	console.print_item('  Blobs: /api/blobs')
	console.print_item('  Symlinks: /api/symlinks')
	console.print_item('  Tools: /api/tools')

	veb.run[FSServer, Context](mut server, server.port)
}

// Global error handler
pub fn (mut server FSServer) before_request(mut ctx Context) {
	if server.cors_enabled {
		// Set CORS headers for all requests
		for origin in server.allowed_origins {
			if origin == '*' || ctx.get_header(.origin) or { '' } == origin {
				ctx.set_header(.access_control_allow_origin, origin)
				break
			}
		}
		ctx.set_header(.access_control_allow_credentials, 'true')
	}
}
