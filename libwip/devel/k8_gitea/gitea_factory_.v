module k8_gitea

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json

__global (
	gitea_global  map[string]&GiteaK8SInstaller
	gitea_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'gitea'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&GiteaK8SInstaller {
	mut obj := GiteaK8SInstaller{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args_ ArgsGet) !&GiteaK8SInstaller {
	mut context := base.context()!
	mut args := args_
	if args.name == 'gitea' && gitea_default != '' {
		args.name = gitea_default
	}

	if args.fromdb || args.name !in gitea_global {
		mut r := context.redis()!
		if r.hexists('context:gitea', args.name)! {
			data := r.hget('context:gitea', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('GiteaK8SInstaller with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(GiteaK8SInstaller, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("GiteaK8SInstaller with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return gitea_global[args.name] or {
		print_backtrace()
		return error('could not get config for gitea with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o GiteaK8SInstaller) ! {
	mut o2 := set_in_mem(o)!
	gitea_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:gitea', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:gitea', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:gitea', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&GiteaK8SInstaller {
	mut res := []&GiteaK8SInstaller{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		gitea_global = map[string]&GiteaK8SInstaller{}
		gitea_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:gitea')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in gitea_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o GiteaK8SInstaller) !GiteaK8SInstaller {
	mut o2 := obj_init(o)!
	gitea_global[o2.name] = &o2
	gitea_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'gitea.') {
		return
	}
	mut install_actions := plbook.find(filter: 'gitea.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'gitea.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action gitea.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action gitea.install')
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
pub fn (mut self GiteaK8SInstaller) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

pub fn (mut self GiteaK8SInstaller) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self GiteaK8SInstaller) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for gitea
pub fn switch(name string) {
	gitea_default = name
}
