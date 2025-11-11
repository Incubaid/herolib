module heropods

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import json

__global (
	heropods_global  map[string]&HeroPods
	heropods_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name       string = 'default' // name of the heropods
	fromdb     bool // will load from filesystem
	create     bool // default will not create if not exist
	reset      bool // will reset the heropods
	use_podman bool = true // will use podman for image management
}

pub fn new(args ArgsGet) !&HeroPods {
	mut obj := HeroPods{
		name:       args.name
		reset:      args.reset
		use_podman: args.use_podman
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&HeroPods {
	mut context := base.context()!
	heropods_default = args.name
	if args.fromdb || args.name !in heropods_global {
		mut r := context.redis()!
		if r.hexists('context:heropods', args.name)! {
			data := r.hget('context:heropods', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('HeroPods with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(HeroPods, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("HeroPods with name '${args.name}' does not exist")
			}
		}
		return get(args)! // no longer from db nor create
	}
	return heropods_global[args.name] or {
		print_backtrace()
		return error('could not get config for heropods with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o HeroPods) ! {
	mut o2 := set_in_mem(o)!
	heropods_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:heropods', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:heropods', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:heropods', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&HeroPods {
	mut res := []&HeroPods{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		heropods_global = map[string]&HeroPods{}
		heropods_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:heropods')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in heropods_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o HeroPods) !HeroPods {
	mut o2 := obj_init(o)!
	heropods_global[o2.name] = &o2
	heropods_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'heropods.') {
		return
	}
	mut install_actions := plbook.find(filter: 'heropods.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
}

// switch instance to be used for heropods
pub fn switch(name string) {
	heropods_default = name
}
