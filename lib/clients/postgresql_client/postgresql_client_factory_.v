module postgresql_client

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json

__global (
	postgresql_client_global  map[string]&PostgresqlClient
	postgresql_client_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&PostgresqlClient {
	mut obj := PostgresqlClient{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&PostgresqlClient {
	mut context := base.context()!
	postgresql_client_default = args.name
	if args.fromdb || args.name !in postgresql_client_global {
		mut r := context.redis()!
		if r.hexists('context:postgresql_client', args.name)! {
			data := r.hget('context:postgresql_client', args.name)!
			if data.len == 0 {
				return error('PostgresqlClient with name: postgresql_client does not exist, prob bug.')
			}
			mut obj := json.decode(PostgresqlClient, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				return error("PostgresqlClient with name 'postgresql_client' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return postgresql_client_global[args.name] or {
		return error('could not get config for postgresql_client with name:postgresql_client')
	}
}

// register the config for the future
pub fn set(o PostgresqlClient) ! {
	mut o2 := set_in_mem(o)!
	postgresql_client_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:postgresql_client', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:postgresql_client', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:postgresql_client', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&PostgresqlClient {
	mut res := []&PostgresqlClient{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		postgresql_client_global = map[string]&PostgresqlClient{}
		postgresql_client_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:postgresql_client')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in postgresql_client_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o PostgresqlClient) !PostgresqlClient {
	mut o2 := obj_init(o)!
	postgresql_client_global[o2.name] = &o2
	postgresql_client_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'postgresql_client.') {
		return
	}
	mut install_actions := plbook.find(filter: 'postgresql_client.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
		}
	}
}

// switch instance to be used for postgresql_client
pub fn switch(name string) {
	postgresql_client_default = name
}
