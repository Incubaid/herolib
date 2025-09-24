module heroprompt

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json

__global (
	heroprompt_global  map[string]&Workspace
	heroprompt_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	path   string
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&Workspace {
	mut obj := Workspace{
		name:      args.name
		base_path: args.path
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&Workspace {
	mut context := base.context()!
	heroprompt_default = args.name
	if args.fromdb || args.name !in heroprompt_global {
		mut r := context.redis()!
		if r.hexists('context:heroprompt', args.name)! {
			data := r.hget('context:heroprompt', args.name)!
			if data.len == 0 {
				return error('Workspace with name: heroprompt does not exist, prob bug.')
			}
			mut obj := json.decode(Workspace, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				return error("Workspace with name 'heroprompt' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return heroprompt_global[args.name] or {
		return error('could not get config for heroprompt with name:heroprompt')
	}
}

// register the config for the future
pub fn set(o Workspace) ! {
	mut o2 := set_in_mem(o)!
	heroprompt_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:heroprompt', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:heroprompt', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:heroprompt', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&Workspace {
	mut res := []&Workspace{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		heroprompt_global = map[string]&Workspace{}
		heroprompt_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:heroprompt')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in heroprompt_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o Workspace) !Workspace {
	mut o2 := obj_init(o)!
	heroprompt_global[o2.name] = &o2
	heroprompt_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'heroprompt.') {
		return
	}
	// 1) Configure workspaces
	mut cfg_actions := plbook.find(filter: 'heroprompt.configure')!
	for cfg_action in cfg_actions {
		heroscript := cfg_action.heroscript()
		mut obj := heroscript_loads(heroscript)!
		set(obj)!
	}
	// 2) Add directories
	for action in plbook.find(filter: 'heroprompt.add_dir')! {
		mut p := action.params
		wsname := p.get_default('name', heroprompt_default)!
		mut wsp := get(name: wsname)!
		path := p.get('path') or { return error("heroprompt.add_dir requires 'path'") }
		wsp.add_dir(path: path)!
	}
	// 3) Add files
	for action in plbook.find(filter: 'heroprompt.add_file')! {
		mut p := action.params
		wsname := p.get_default('name', heroprompt_default)!
		mut wsp := get(name: wsname)!
		path := p.get('path') or { return error("heroprompt.add_file requires 'path'") }
		wsp.add_file(path: path)!
	}
}

// switch instance to be used for heroprompt
pub fn switch(name string) {
	heroprompt_default = name
}
