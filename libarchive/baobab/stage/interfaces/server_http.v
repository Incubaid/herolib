module interfaces

import freeflowuniverse.herolib.schemas.openapi { OpenAPI }
import freeflowuniverse.herolib.baobab.stage { ClientConfig }
import freeflowuniverse.herolib.schemas.openrpc { OpenRPC }
import veb

pub struct HTTPServer {
	veb.Controller
}

pub struct Context {
	veb.Context
}

pub struct HTTPServerConfig {
	ClientConfig
pub:
	openapi_specification OpenAPI
	openrpc_specification OpenRPC
}

pub fn new_http_server() !&HTTPServer {
	mut s := &HTTPServer{}

	// client := actor.new_client(cfg.ClientConfig)!

	// openapi_proxy := new_openapi_proxy(
	// 	client:        new_client(cfg.ClientConfig)!
	// 	specification: cfg.openapi_spec
	// )

	// mut openrpc_controller := openrpc.new_http_controller(
	// 	specification: cfg.openrpc_specification
	// 	handler: new_openrpc_interface(client)
	// )
	// s.register_controller[openrpc.HTTPController, Context]('/openrpc', mut openrpc_controller)!
	return s
}

pub fn (mut server HTTPServer) run() {
	veb.run[HTTPServer, Context](mut server, 8082)
}
