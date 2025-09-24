module zerodb_client

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json

__global (
	zerodb_client_global  map[string]&ZeroDBClient
	zerodb_client_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&ZeroDBClient {
	mut obj := ZeroDBClient{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&ZeroDBClient {
	mut context := base.context()!
	zerodb_client_default = args.name
	if args.fromdb || args.name !in zerodb_client_global {
		mut r := context.redis()!
		if r.hexists('context:zerodb_client', args.name)! {
			data := r.hget('context:zerodb_client', args.name)!
			if data.len == 0 {
				return error('ZeroDBClient with name: zerodb_client does not exist, prob bug.')
			}
			mut obj := json.decode(ZeroDBClient, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				return error("ZeroDBClient with name 'zerodb_client' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return zerodb_client_global[args.name] or {
		return error('could not get config for zerodb_client with name:zerodb_client')
	}
}

// register the config for the future
pub fn set(o ZeroDBClient) ! {
	mut o2 := set_in_mem(o)!
	zerodb_client_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:zerodb_client', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:zerodb_client', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:zerodb_client', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&ZeroDBClient {
	mut res := []&ZeroDBClient{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		zerodb_client_global = map[string]&ZeroDBClient{}
		zerodb_client_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:zerodb_client')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in zerodb_client_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o ZeroDBClient) !ZeroDBClient {
	mut o2 := obj_init(o)!
	zerodb_client_global[o2.name] = &o2
	zerodb_client_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'zerodb_client.') {
		return
	}
	mut install_actions := plbook.find(filter: 'zerodb_client.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
		}
	}
}

// switch instance to be used for zerodb_client
pub fn switch(name string) {
}
