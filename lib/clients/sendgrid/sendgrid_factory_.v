module sendgrid

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json

__global (
	sendgrid_global  map[string]&SendGrid
	sendgrid_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&SendGrid {
	mut obj := SendGrid{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&SendGrid {
	mut context := base.context()!
	sendgrid_default = args.name
	if args.fromdb || args.name !in sendgrid_global {
		mut r := context.redis()!
		if r.hexists('context:sendgrid', args.name)! {
			data := r.hget('context:sendgrid', args.name)!
			if data.len == 0 {
				return error('SendGrid with name: sendgrid does not exist, prob bug.')
			}
			mut obj := json.decode(SendGrid, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				return error("SendGrid with name 'sendgrid' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return sendgrid_global[args.name] or {
		return error('could not get config for sendgrid with name:sendgrid')
	}
}

// register the config for the future
pub fn set(o SendGrid) ! {
	mut o2 := set_in_mem(o)!
	sendgrid_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:sendgrid', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:sendgrid', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:sendgrid', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&SendGrid {
	mut res := []&SendGrid{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		sendgrid_global = map[string]&SendGrid{}
		sendgrid_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:sendgrid')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in sendgrid_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o SendGrid) !SendGrid {
	mut o2 := obj_init(o)!
	sendgrid_global[o2.name] = &o2
	sendgrid_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'sendgrid.') {
		return
	}
	mut install_actions := plbook.find(filter: 'sendgrid.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
		}
	}
}

// switch instance to be used for sendgrid
pub fn switch(name string) {
}
