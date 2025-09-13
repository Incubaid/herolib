module openrpc

import freeflowuniverse.herolib.schemas.openrpc

// HeroModelsServer extends the base openrpcserver.RPCServer with heromodels-specific functionality
pub struct HeroModelsServer {
	openrpc.UNIXServer
}

@[params]
pub struct HeroModelsServerArgs {
pub mut:
	socket_path string = '/tmp/heromodels'
}

// new_heromodels_server creates a new HeroModels RPC server
pub fn new_heromodels_server(args HeroModelsServerArgs) !&HeroModelsServer {
	mut base_server := openrpc.new_unix_server(
		new_heromodels_handler()!,
		socket_path: args.socket_path
	)!
	
	return &HeroModelsServer{
		UNIXServer: *base_server
	}
}