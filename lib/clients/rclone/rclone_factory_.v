module rclone

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json

__global (
	rclone_global  map[string]&RCloneClient
	rclone_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&RCloneClient {
	mut obj := RCloneClient{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&RCloneClient {
	mut context := base.context()!
	rclone_default = args.name
	if args.fromdb || args.name !in rclone_global {
		mut r := context.redis()!
		if r.hexists('context:rclone', args.name)! {
			data := r.hget('context:rclone', args.name)!
			if data.len == 0 {
				return error('RCloneClient with name: rclone does not exist, prob bug.')
			}
			mut obj := json.decode(RCloneClient, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				return error("RCloneClient with name 'rclone' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return rclone_global[args.name] or {
		return error('could not get config for rclone with name:rclone')
	}
}

// register the config for the future
pub fn set(o RCloneClient) ! {
	mut o2 := set_in_mem(o)!
	rclone_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:rclone', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:rclone', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:rclone', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&RCloneClient {
	mut res := []&RCloneClient{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		rclone_global = map[string]&RCloneClient{}
		rclone_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:rclone')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in rclone_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o RCloneClient) !RCloneClient {
	mut o2 := obj_init(o)!
	rclone_global[o2.name] = &o2
	rclone_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'rclone.') {
		return
	}
	mut install_actions := plbook.find(filter: 'rclone.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
		}
	}
}

// switch instance to be used for rclone
pub fn switch(name string) {
}
