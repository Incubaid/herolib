module kubernetes_installer

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json

__global (
	kubernetes_installer_global  map[string]&KubernetesInstaller
	kubernetes_installer_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&KubernetesInstaller {
	mut obj := KubernetesInstaller{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&KubernetesInstaller {
	mut context := base.context()!
	kubernetes_installer_default = args.name
	if args.fromdb || args.name !in kubernetes_installer_global {
		mut r := context.redis()!
		if r.hexists('context:kubernetes_installer', args.name)! {
			data := r.hget('context:kubernetes_installer', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('KubernetesInstaller with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(KubernetesInstaller, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("KubernetesInstaller with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return kubernetes_installer_global[args.name] or {
		print_backtrace()
		return error('could not get config for kubernetes_installer with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o KubernetesInstaller) ! {
	mut o2 := set_in_mem(o)!
	kubernetes_installer_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:kubernetes_installer', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:kubernetes_installer', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:kubernetes_installer', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&KubernetesInstaller {
	mut res := []&KubernetesInstaller{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		kubernetes_installer_global = map[string]&KubernetesInstaller{}
		kubernetes_installer_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:kubernetes_installer')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in kubernetes_installer_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o KubernetesInstaller) !KubernetesInstaller {
	mut o2 := obj_init(o)!
	kubernetes_installer_global[o2.name] = &o2
	kubernetes_installer_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'kubernetes_installer.') {
		return
	}
	mut install_actions := plbook.find(filter: 'kubernetes_installer.configure')!
	if install_actions.len > 0 {
		return error("can't configure kubernetes_installer, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'kubernetes_installer.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action kubernetes_installer.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action kubernetes_installer.install')
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
pub fn (mut self KubernetesInstaller) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

pub fn (mut self KubernetesInstaller) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self KubernetesInstaller) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for kubernetes_installer
pub fn switch(name string) {
	kubernetes_installer_default = name
}
