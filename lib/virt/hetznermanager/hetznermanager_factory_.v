module hetznermanager

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json

__global (
	hetznermanager_global  map[string]&HetznerManager
	hetznermanager_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&HetznerManager {
	mut obj := HetznerManager{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&HetznerManager {
	mut context := base.context()!
	hetznermanager_default = args.name
	if args.fromdb || args.name !in hetznermanager_global {
		mut r := context.redis()!
		if r.hexists('context:hetznermanager', args.name)! {
			data := r.hget('context:hetznermanager', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('HetznerManager with name: hetznermanager does not exist, prob bug.')
			}
			mut obj := json.decode(HetznerManager, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("HetznerManager with name 'hetznermanager' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return hetznermanager_global[args.name] or {
		print_backtrace()
		return error('could not get config for hetznermanager with name:hetznermanager')
	}
}

// register the config for the future
pub fn set(o HetznerManager) ! {
	mut o2 := set_in_mem(o)!
	hetznermanager_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:hetznermanager', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:hetznermanager', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:hetznermanager', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&HetznerManager {
	mut res := []&HetznerManager{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		hetznermanager_global = map[string]&HetznerManager{}
		hetznermanager_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:hetznermanager')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in hetznermanager_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o HetznerManager) !HetznerManager {
	mut o2 := obj_init(o)!
	hetznermanager_global[o2.name] = &o2
	hetznermanager_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'hetznermanager.') {
		return
	}
	mut install_actions := plbook.find(filter: 'hetznermanager.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
}

// switch instance to be used for hetznermanager
pub fn switch(name string) {
	hetznermanager_default = name
}
