module cryptpad

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json

__global (
	cryptpad_global  map[string]&CryptpadServer
	cryptpad_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'cryptpad'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&CryptpadServer {
	mut obj := CryptpadServer{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args_ ArgsGet) !&CryptpadServer {
	mut args := args_
	mut context := base.context()!
	if args.name == 'cryptpad' && cryptpad_default != '' {
		args.name = cryptpad_default
	}
	if args.fromdb || args.name !in cryptpad_global {
		mut r := context.redis()!
		if r.hexists('context:cryptpad', args.name)! {
			data := r.hget('context:cryptpad', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('CryptpadServer with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(CryptpadServer, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("CryptpadServer with name '${args.name}' does not exist")
			}
		}
		return get(
			name:   args.name
			fromdb: args.fromdb
			create: args.create
		)! // no longer from db nor create
	}
	result := cryptpad_global[args.name] or {
		print_backtrace()
		return error('could not get config for cryptpad with name:${args.name}')
	}
	return result
}

// register the config for the future
pub fn set(o CryptpadServer) ! {
	mut o2 := set_in_mem(o)!
	cryptpad_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	encoded := json.encode(o2)
	r.hset('context:cryptpad', o2.name, encoded)!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:cryptpad', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:cryptpad', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&CryptpadServer {
	mut res := []&CryptpadServer{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		cryptpad_global = map[string]&CryptpadServer{}
		cryptpad_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:cryptpad')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in cryptpad_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o CryptpadServer) !CryptpadServer {
	mut o2 := obj_init(o)!
	cryptpad_global[o2.name] = &o2
	cryptpad_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'cryptpad.') {
		return
	}
	mut install_actions := plbook.find(filter: 'cryptpad.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'cryptpad.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action cryptpad.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action cryptpad.install')
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
pub fn (mut self CryptpadServer) reload() ! {
	self = obj_init(self)!
	set(self)!
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

pub fn (mut self CryptpadServer) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self CryptpadServer) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for cryptpad
pub fn switch(name string) {
	cryptpad_default = name
}
