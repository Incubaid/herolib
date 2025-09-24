module zinit

import freeflowuniverse.herolib.data.encoderhero
import freeflowuniverse.herolib.schemas.jsonrpc
import os

pub const version = '0.0.0'
const singleton = true
const default = false

// // Factory function to create a new ZinitRPC client instance
// @[params]
// pub struct NewClientArgs {
// pub mut:
// 	name        string = 'default'
// 	socket_path string
// }

// pub fn new_client(args NewClientArgs) !&ZinitRPC {
// 	mut client := ZinitRPC{
// 		name:        args.name
// 		socket_path: args.socket_path
// 	}
// 	client = obj_init(client)!
// 	return &client
// }

@[heap]
pub struct ZinitRPC {
pub mut:
	name        string = 'default'
	socket_path string
	// rpc_client  ?&jsonrpc.Client @[skip]
}

// your checking & initialization code if needed
fn obj_init(mycfg_ ZinitRPC) !ZinitRPC {
	mut mycfg := mycfg_
	if mycfg.socket_path == '' {
		mycfg.socket_path = '/tmp/zinit.sock'
	}
	return mycfg
}

pub fn heroscript_loads(heroscript string) !ZinitRPC {
	mut obj := encoderhero.decode[ZinitRPC](heroscript)!
	return obj
}
