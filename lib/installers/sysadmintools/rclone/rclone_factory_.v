module rclone

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager

__global (
	rclone_global  map[string]&RClone
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

pub fn new(args ArgsGet) !&RClone {
	mut obj := RClone{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&RClone {
	mut context := base.context()!
	rclone_default = args.name
	if args.fromdb || args.name !in rclone_global {
		mut r := context.redis()!
		if r.hexists('context:rclone', args.name)! {
			data := r.hget('context:rclone', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('RClone with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(RClone, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("RClone with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return rclone_global[args.name] or {
		print_backtrace()
		return error('could not get config for rclone with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o RClone) ! {
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
pub fn list(args ArgsList) ![]&RClone {
	mut res := []&RClone{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		rclone_global = map[string]&RClone{}
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
fn set_in_mem(o RClone) !RClone {
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
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'rclone.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action rclone.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action rclone.install')
				install()!
			}
		}
		other_action.done = true
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////# LIVE CYCLE MANAGEMENT FOR INSTALLERS ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

// load from disk and make sure is properly intialized
pub fn (mut self RClone) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

pub fn (mut self RClone) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self RClone) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for rclone
pub fn switch(name string) {
	rclone_default = name
}
