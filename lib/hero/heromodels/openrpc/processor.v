module openrpc

import freeflowuniverse.herolib.schemas.openrpcserver

// HeroModelsServer extends the base openrpcserver.RPCServer with heromodels-specific functionality
pub struct HeroModelsServer {
	openrpcserver.RPCServer
}

@[params]
pub struct HeroModelsServerArgs {
pub mut:
	socket_path string = '/tmp/heromodels'
}

// new_heromodels_server creates a new HeroModels RPC server
pub fn new_heromodels_server(args HeroModelsServerArgs) !&HeroModelsServer {
	base_server := openrpcserver.new_rpc_server(
		socket_path: args.socket_path
	)!

	return &HeroModelsServer{
		RPCServer: *base_server
	}
}

// process extends the base process method with heromodels-specific methods
pub fn (mut server HeroModelsServer) process(method string, params_str string) !string {
	// Route to heromodels-specific methods first
	result := match method {
		'comment_get' {
			comment_get(params_str)!
		}
		'comment_set' {
			comment_set(params_str)!
		}
		'comment_delete' {
			comment_delete(params_str)!
		}
		'comment_list' {
			comment_list()!
		}
		'rpc.discover' {
			server.discover()!
		}
		else {
			return server.create_error_response(-32601, 'Method not found', method)
		}
	}

	return result
}
