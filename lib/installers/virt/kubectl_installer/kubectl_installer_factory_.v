module kubectl_installer

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager

__global (
	kubectl_installer_global  map[string]&KubectlInstaller
	kubectl_installer_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&KubectlInstaller {
	mut obj := KubectlInstaller{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&KubectlInstaller {
	mut context := base.context()!
	kubectl_installer_default = args.name
	if args.fromdb || args.name !in kubectl_installer_global {
		mut r := context.redis()!
		if r.hexists('context:kubectl_installer', args.name)! {
			data := r.hget('context:kubectl_installer', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('KubectlInstaller with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(KubectlInstaller, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("KubectlInstaller with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return kubectl_installer_global[args.name] or {
		print_backtrace()
		return error('could not get config for kubectl_installer with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o KubectlInstaller) ! {
	mut o2 := set_in_mem(o)!
	kubectl_installer_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:kubectl_installer', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:kubectl_installer', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:kubectl_installer', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&KubectlInstaller {
	mut res := []&KubectlInstaller{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		kubectl_installer_global = map[string]&KubectlInstaller{}
		kubectl_installer_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:kubectl_installer')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in kubectl_installer_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o KubectlInstaller) !KubectlInstaller {
	mut o2 := obj_init(o)!
	kubectl_installer_global[o2.name] = &o2
	kubectl_installer_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'kubectl_installer.') {
		return
	}
	mut install_actions := plbook.find(filter: 'kubectl_installer.configure')!
	if install_actions.len > 0 {
		return error("can't configure kubectl_installer, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'kubectl_installer.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action kubectl_installer.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action kubectl_installer.install')
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
pub fn (mut self KubectlInstaller) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self KubectlInstaller) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self KubectlInstaller) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for kubectl_installer
pub fn switch(name string) {
	kubectl_installer_default = name
}
