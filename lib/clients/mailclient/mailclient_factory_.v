module mailclient

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json

__global (
	mailclient_global  map[string]&MailClient
	mailclient_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&MailClient {
	mut obj := MailClient{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&MailClient {
	mut context := base.context()!
	mailclient_default = args.name
	if args.fromdb || args.name !in mailclient_global {
		mut r := context.redis()!
		if r.hexists('context:mailclient', args.name)! {
			data := r.hget('context:mailclient', args.name)!
			if data.len == 0 {
				return error('MailClient with name: mailclient does not exist, prob bug.')
			}
			mut obj := json.decode(MailClient, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				return error("MailClient with name 'mailclient' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return mailclient_global[args.name] or {
		return error('could not get config for mailclient with name:mailclient')
	}
}

// register the config for the future
pub fn set(o MailClient) ! {
	mut o2 := set_in_mem(o)!
	mailclient_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:mailclient', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:mailclient', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:mailclient', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&MailClient {
	mut res := []&MailClient{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		mailclient_global = map[string]&MailClient{}
		mailclient_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:mailclient')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in mailclient_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o MailClient) !MailClient {
	mut o2 := obj_init(o)!
	mailclient_global[o2.name] = &o2
	mailclient_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'mailclient.') {
		return
	}
	mut install_actions := plbook.find(filter: 'mailclient.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
		}
	}
}

// switch instance to be used for mailclient
pub fn switch(name string) {
	mailclient_default = name
}
