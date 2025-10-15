module deployer

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json

__global (
	deployer_global  map[string]&TFGridDeployer
	deployer_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&TFGridDeployer {
	mut obj := TFGridDeployer{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&TFGridDeployer {
	mut context := base.context()!
	deployer_default = args.name
	if args.fromdb || args.name !in deployer_global {
		mut r := context.redis()!
		if r.hexists('context:deployer', args.name)! {
			data := r.hget('context:deployer', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('TFGridDeployer with name: deployer does not exist, prob bug.')
			}
			mut obj := json.decode(TFGridDeployer, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("TFGridDeployer with name 'deployer' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return deployer_global[args.name] or {
		print_backtrace()
		return error('could not get config for deployer with name:deployer')
	}
}

// register the config for the future
pub fn set(o TFGridDeployer) ! {
	mut o2 := set_in_mem(o)!
	deployer_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:deployer', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:deployer', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:deployer', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&TFGridDeployer {
	mut res := []&TFGridDeployer{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		deployer_global = map[string]&TFGridDeployer{}
		deployer_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:deployer')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in deployer_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o TFGridDeployer) !TFGridDeployer {
	mut o2 := obj_init(o)!
	deployer_global[o2.name] = &o2
	deployer_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'deployer.') {
		return
	}
	mut install_actions := plbook.find(filter: 'deployer.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
}

// switch instance to be used for deployer
pub fn switch(name string) {
	deployer_default = name
}
