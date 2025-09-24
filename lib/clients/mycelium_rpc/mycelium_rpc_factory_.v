module mycelium_rpc

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json

__global (
	mycelium_rpc_global  map[string]&MyceliumRPC
	mycelium_rpc_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&MyceliumRPC {
	mut obj := MyceliumRPC{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&MyceliumRPC {
	mut context := base.context()!
	mycelium_rpc_default = args.name
	if args.fromdb || args.name !in mycelium_rpc_global {
		mut r := context.redis()!
		if r.hexists('context:mycelium_rpc', args.name)! {
			data := r.hget('context:mycelium_rpc', args.name)!
			if data.len == 0 {
				return error('MyceliumRPC with name: mycelium_rpc does not exist, prob bug.')
			}
			mut obj := json.decode(MyceliumRPC, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				return error("MyceliumRPC with name 'mycelium_rpc' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return mycelium_rpc_global[args.name] or {
		return error('could not get config for mycelium_rpc with name:mycelium_rpc')
	}
}

// register the config for the future
pub fn set(o MyceliumRPC) ! {
	mut o2 := set_in_mem(o)!
	mycelium_rpc_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:mycelium_rpc', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:mycelium_rpc', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:mycelium_rpc', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&MyceliumRPC {
	mut res := []&MyceliumRPC{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		mycelium_rpc_global = map[string]&MyceliumRPC{}
		mycelium_rpc_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:mycelium_rpc')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in mycelium_rpc_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o MyceliumRPC) !MyceliumRPC {
	mut o2 := obj_init(o)!
	mycelium_rpc_global[o2.name] = &o2
	mycelium_rpc_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'mycelium_rpc.') {
		return
	}
	mut install_actions := plbook.find(filter: 'mycelium_rpc.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
		}
	}
}

// switch instance to be used for mycelium_rpc
pub fn switch(name string) {
}
