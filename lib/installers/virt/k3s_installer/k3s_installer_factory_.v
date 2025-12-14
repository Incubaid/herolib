module k3s_installer

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	k3s_installer_global  map[string]&K3SInstaller
	k3s_installer_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&K3SInstaller {
	mut obj := K3SInstaller{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&K3SInstaller {
	mut context := base.context()!
	k3s_installer_default = args.name
	if args.fromdb || args.name !in k3s_installer_global {
		mut r := context.redis()!
		if r.hexists('context:k3s_installer', args.name)! {
			data := r.hget('context:k3s_installer', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('K3SInstaller with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(K3SInstaller, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("K3SInstaller with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return k3s_installer_global[args.name] or {
		print_backtrace()
		return error('could not get config for k3s_installer with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o K3SInstaller) ! {
	mut o2 := set_in_mem(o)!
	k3s_installer_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:k3s_installer', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:k3s_installer', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:k3s_installer', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&K3SInstaller {
	mut res := []&K3SInstaller{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		k3s_installer_global = map[string]&K3SInstaller{}
		k3s_installer_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:k3s_installer')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in k3s_installer_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o K3SInstaller) !K3SInstaller {
	mut o2 := obj_init(o)!
	k3s_installer_global[o2.name] = &o2
	k3s_installer_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'k3s_installer.') {
		return
	}
	mut install_actions := plbook.find(filter: 'k3s_installer.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'k3s_installer.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build', 'start', 'stop', 'restart',
			'start_pre', 'start_post', 'stop_pre', 'stop_post', 'install_master', 'join_master',
			'install_worker'] {
			mut p := other_action.params
			name := p.get_default('name', 'default')!
			reset := p.get_default_false('reset')
			mut k3s_installer_obj := get(name: name)!
			console.print_debug('action object:\n${k3s_installer_obj}')

			if other_action.name == 'destroy' || reset {
				console.print_debug('install action k3s_installer.destroy')
				k3s_installer_obj.destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action k3s_installer.install')
				k3s_installer_obj.install(reset: reset)!
			}
			if other_action.name == 'install_master' {
				console.print_debug('install action k3s_installer.install_master')
				k3s_installer_obj.install_master()!
			}
			if other_action.name == 'join_master' {
				console.print_debug('install action k3s_installer.join_master')
				k3s_installer_obj.join_master()!
			}
			if other_action.name == 'install_worker' {
				console.print_debug('install action k3s_installer.install_worker')
				k3s_installer_obj.install_worker()!
			}
			if other_action.name == 'build' {
				console.print_debug('install action k3s_installer.build')
				k3s_installer_obj.build()!
			}
			if other_action.name == 'start' {
				console.print_debug('install action k3s_installer.${other_action.name}')
				k3s_installer_obj.start(reset: reset)!
			}
			if other_action.name == 'stop' {
				console.print_debug('install action k3s_installer.${other_action.name}')
				k3s_installer_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action k3s_installer.${other_action.name}')
				k3s_installer_obj.restart(reset: reset)!
			}
			if other_action.name == 'start_pre' {
				console.print_debug('install action k3s_installer.${other_action.name}')
				k3s_installer_obj.start_pre()!
			}
			if other_action.name == 'start_post' {
				console.print_debug('install action k3s_installer.${other_action.name}')
				k3s_installer_obj.start_post()!
			}
			if other_action.name == 'stop_pre' {
				console.print_debug('install action k3s_installer.${other_action.name}')
				k3s_installer_obj.stop_pre()!
			}
			if other_action.name == 'stop_post' {
				console.print_debug('install action k3s_installer.${other_action.name}')
				k3s_installer_obj.stop_post()!
			}
		}
		other_action.done = true
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////# LIVE CYCLE MANAGEMENT FOR INSTALLERS ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

fn startupmanager_get(cat startupmanager.StartupManagerType) !startupmanager.StartupManager {
	// unknown
	// screen
	// zinit
	// tmux
	// systemd
	match cat {
		.screen {
			console.print_debug("installer: k3s_installer' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: k3s_installer' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: k3s_installer' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: k3s_installer' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self K3SInstaller) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self K3SInstaller) start(args StartArgs) ! {
	switch(self.name)

	if self.running()! {
		return
	}

	console.print_header('installer: k3s_installer start')

	if !self.installed()! {
		self.install()!
	}

	self.start_pre()!

	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: k3s_installer starting with ${zprocess.startuptype}...')

		sm.new(zprocess)!

		sm.start(zprocess.name)!
	}

	self.start_post()!

	for _ in 0 .. 50 {
		if self.running()! {
			return
		}
		time.sleep(100 * time.millisecond)
	}
	return error('k3s_installer did not install properly.')
}

pub fn (mut self K3SInstaller) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start(reset: false)!
}

pub fn (mut self K3SInstaller) stop() ! {
	switch(self.name)
	self.stop_pre()!
	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	self.stop_post()!
}

pub fn (mut self K3SInstaller) restart(args StartArgs) ! {
	switch(self.name)
	self.stop()!
	self.start(args)!
}

pub fn (mut self K3SInstaller) running() !bool {
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
	return self.running_check()!
}

pub fn (self &K3SInstaller) installed() !bool {
	return installed()!
}

pub fn (mut self K3SInstaller) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self K3SInstaller) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for k3s_installer
pub fn switch(name string) {
	k3s_installer_default = name
}
