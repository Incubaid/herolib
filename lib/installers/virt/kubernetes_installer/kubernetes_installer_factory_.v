module kubernetes_installer

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

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
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'kubernetes_installer.')!
	for mut other_action in other_actions {
		mut p := other_action.params
		name := p.get_default('name', 'default')!
		reset := p.get_default_false('reset')
		mut k8s_obj := get(name: name, create: true)!
		console.print_debug('action object:\n${k8s_obj}')

		if other_action.name in ['destroy', 'install', 'build'] {
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action kubernetes_installer.destroy')
				k8s_obj.destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action kubernetes_installer.install')
				k8s_obj.install(reset: reset)!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			if other_action.name == 'start' {
				console.print_debug('install action kubernetes_installer.${other_action.name}')
				k8s_obj.start()!
			}
			if other_action.name == 'stop' {
				console.print_debug('install action kubernetes_installer.${other_action.name}')
				k8s_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action kubernetes_installer.${other_action.name}')
				k8s_obj.restart()!
			}
		}
		// K3s-specific actions
		if other_action.name in ['install_master', 'join_master', 'install_worker'] {
			if other_action.name == 'install_master' {
				console.print_debug('install action kubernetes_installer.install_master')
				k8s_obj.install_master()!
			}
			if other_action.name == 'join_master' {
				console.print_debug('install action kubernetes_installer.join_master')
				k8s_obj.join_master()!
			}
			if other_action.name == 'install_worker' {
				console.print_debug('install action kubernetes_installer.install_worker')
				k8s_obj.install_worker()!
			}
		}
		if other_action.name == 'get_kubeconfig' {
			console.print_debug('install action kubernetes_installer.get_kubeconfig')
			kubeconfig := k8s_obj.get_kubeconfig()!
			console.print_header('Kubeconfig:\n${kubeconfig}')
		}
		if other_action.name == 'generate_join_script' {
			console.print_debug('install action kubernetes_installer.generate_join_script')
			script := k8s_obj.generate_join_script()!
			console.print_header('Join Script:\n${script}')
		}
		other_action.done = true
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////# LIVE CYCLE MANAGEMENT FOR INSTALLERS ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

fn startupmanager_get(cat startupmanager.StartupManagerType) !startupmanager.StartupManager {
	match cat {
		.screen {
			console.print_debug("installer: kubernetes_installer' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: kubernetes_installer' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: kubernetes_installer' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: kubernetes_installer' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self KubernetesInstaller) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self KubernetesInstaller) start() ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('installer: kubernetes_installer start')

	if !installed()! {
		return error('K3s is not installed. Please run install_master, join_master, or install_worker first.')
	}

	configure()!

	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: kubernetes_installer starting with ${zprocess.startuptype}...')

		sm.new(zprocess)!

		sm.start(zprocess.name)!
	}

	for _ in 0 .. 50 {
		if self.running()! {
			return
		}
		time.sleep(100 * time.millisecond)
	}
	return error('kubernetes_installer did not start properly.')
}

pub fn (mut self KubernetesInstaller) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self KubernetesInstaller) stop() ! {
	switch(self.name)
	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
}

pub fn (mut self KubernetesInstaller) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self KubernetesInstaller) running() !bool {
	switch(self.name)

	// walk over the generic processes, if not running return
	for zprocess in self.startupcmd()! {
		if zprocess.startuptype != .screen {
			mut sm := startupmanager_get(zprocess.startuptype)!
			r := sm.running(zprocess.name)!
			if r == false {
				return false
			}
		}
	}
	return running()!
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
	self.stop() or {}
	destroy()!
}

// switch instance to be used for kubernetes_installer
pub fn switch(name string) {
	kubernetes_installer_default = name
}
