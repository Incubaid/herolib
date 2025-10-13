module webdav

import veb
import incubaid.herolib.ui.console
import incubaid.herolib.vfs

@[heap]
pub struct Server {
	veb.Middleware[Context]
pub mut:
	lock_manager Locker
	user_db      map[string]string @[required]
	vfs          vfs.VFSImplementation
}

pub struct Context {
	veb.Context
}

@[params]
pub struct ServerArgs {
pub mut:
	user_db map[string]string @[required]
	vfs     vfs.VFSImplementation
}

pub fn new_server(args ServerArgs) !&Server {
	mut server := &Server{
		user_db: args.user_db.clone()
		vfs:     args.vfs
	}

	// register middlewares for all routes
	server.use(handler: middleware_log_request)
	server.use(handler: server.auth_middleware)
	server.use(handler: middleware_log_response, after: true)
	return server
}

@[params]
pub struct RunParams {
pub mut:
	port       int = 8088
	background bool
}

pub fn (mut server Server) run(params RunParams) {
	console.print_green('Running the server on port: ${params.port}')
	if params.background {
		spawn veb.run[Server, Context](mut server, params.port)
	} else {
		veb.run[Server, Context](mut server, params.port)
	}
}
