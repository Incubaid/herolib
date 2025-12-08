module zinit

import incubaid.herolib.data.encoderhero
import os

pub const version = '0.0.0'
const singleton = true
const default = false

// Common zinit socket paths to check
const socket_paths = ['/var/run/zinit.sock', '/tmp/zinit.sock']

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
		// Auto-detect socket path by checking common locations
		mycfg.socket_path = detect_socket_path()
	}
	return mycfg
}

// detect_socket_path tries common socket locations and returns the first one that exists
fn detect_socket_path() string {
	for path in socket_paths {
		if os.exists(path) {
			return path
		}
	}
	// Default fallback if none found
	return '/tmp/zinit.sock'
}

pub fn heroscript_loads(heroscript string) !ZinitRPC {
	mut obj := encoderhero.decode[ZinitRPC](heroscript)!
	return obj
}