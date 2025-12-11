module k8_element_chat

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json

__global (
	element_chat_global  map[string]&ElementChat
	element_chat_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = element_chat_default
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&ElementChat {
	mut obj := ElementChat{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&ElementChat {
	mut context := base.context()!
	element_chat_default = args.name
	if args.fromdb || args.name !in element_chat_global {
		mut r := context.redis()!
		if r.hexists('context:element_chat', args.name)! {
			data := r.hget('context:element_chat', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('ElementChat with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(ElementChat, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("ElementChat with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return element_chat_global[args.name] or {
		print_backtrace()
		return error('could not get config for element_chat with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o ElementChat) ! {
	mut o2 := set_in_mem(o)!
	element_chat_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:element_chat', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:element_chat', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:element_chat', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&ElementChat {
	mut res := []&ElementChat{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		element_chat_global = map[string]&ElementChat{}
		element_chat_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:element_chat')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in element_chat_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o ElementChat) !ElementChat {
	mut o2 := obj_init(o)!
	element_chat_global[o2.name] = &o2
	element_chat_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'element_chat.') {
		return
	}
	mut install_actions := plbook.find(filter: 'element_chat.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'element_chat.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action element_chat.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action element_chat.install')
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
pub fn (mut self ElementChat) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

pub fn (mut self ElementChat) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self ElementChat) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for element_chat
pub fn switch(name string) {
	element_chat_default = name
}
