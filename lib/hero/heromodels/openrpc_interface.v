module heromodels

import freeflowuniverse.herolib.schemas.openrpcserver

// Re-export types from openrpcserver for convenience
pub type Base = openrpcserver.Base
pub type BaseArgs = openrpcserver.BaseArgs
pub type CommentArg = openrpcserver.CommentArg

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

// Re-export core methods from openrpcserver for convenience
pub fn set[T](mut obj T) !u32 {
	return openrpcserver.set[T](mut obj)!
}

pub fn get[T](id u32) !T {
	return openrpcserver.get[T](id)!
}

pub fn exists[T](id u32) !bool {
	return openrpcserver.exists[T](id)!
}

pub fn delete[T](id u32) ! {
	openrpcserver.delete[T](id)!
}

pub fn list[T]() ![]T {
	return openrpcserver.list[T]()!
}

// Re-export utility functions
pub fn tags2id(tags []string) !u32 {
	return openrpcserver.tags2id(tags)!
}

pub fn comment_multiset(args []CommentArg) ![]u32 {
	return openrpcserver.comment_multiset(args)!
}

pub fn comments2ids(args []CommentArg) ![]u32 {
	return openrpcserver.comments2ids(args)!
}

pub fn comment2id(comment string) !u32 {
	return openrpcserver.comment2id(comment)!
}

pub fn new_base(args BaseArgs) !Base {
	return openrpcserver.new_base(args)!
}