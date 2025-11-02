module kubernetes

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import json

__global (
	kubernetes_global  map[string]&KubeClient
	kubernetes_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&KubeClient {
	mut obj := KubeClient{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&KubeClient {
	mut context := base.context()!
	kubernetes_default = args.name
	if args.fromdb || args.name !in kubernetes_global {
		mut r := context.redis()!
		if r.hexists('context:kubernetes', args.name)! {
			data := r.hget('context:kubernetes', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('KubeClient with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(KubeClient, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("KubeClient with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return kubernetes_global[args.name] or {
		print_backtrace()
		return error('could not get config for kubernetes with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o KubeClient) ! {
	mut o2 := set_in_mem(o)!
	kubernetes_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:kubernetes', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:kubernetes', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:kubernetes', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&KubeClient {
	mut res := []&KubeClient{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		kubernetes_global = map[string]&KubeClient{}
		kubernetes_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:kubernetes')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in kubernetes_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o KubeClient) !KubeClient {
	mut o2 := obj_init(o)!
	kubernetes_global[o2.name] = &o2
	kubernetes_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'kubernetes.') {
		return
	}
	mut install_actions := plbook.find(filter: 'kubernetes.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
}

// switch instance to be used for kubernetes
pub fn switch(name string) {
	kubernetes_default = name
}
