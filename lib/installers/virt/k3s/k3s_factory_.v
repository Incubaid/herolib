module k3s

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.osal.core as osal
import time

__global (
	k3s_global  map[string]&K3s
	k3s_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&K3s {
	mut obj := K3s{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&K3s {
	mut context := base.context()!
	k3s_default = args.name
	if args.fromdb || args.name !in k3s_global {
		mut r := context.redis()!
		if r.hexists('context:k3s', args.name)! {
			data := r.hget('context:k3s', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('K3s with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(K3s, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("K3s with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return k3s_global[args.name] or {
		print_backtrace()
		return error('could not get config for k3s with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o K3s) ! {
	mut o2 := set_in_mem(o)!
	k3s_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:k3s', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:k3s', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:k3s', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&K3s {
	mut res := []&K3s{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		k3s_global = map[string]&K3s{}
		k3s_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:k3s')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in k3s_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o K3s) !K3s {
	mut o2 := obj_init(o)!
	k3s_global[o2.name] = &o2
	k3s_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'k3s.') {
		return
	}
	mut install_actions := plbook.find(filter: 'k3s.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'k3s.')!
	for mut other_action in other_actions {
		mut p := other_action.params
		name := p.get_default('name', 'default')!
		reset := p.get_default_false('reset')
		mut k8s_obj := get(name: name, create: true)!
		console.print_debug('action object:\n${k8s_obj}')

		if other_action.name in ['destroy', 'install', 'build'] {
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action k3s.destroy')
				k8s_obj.destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action k3s.install')
				k8s_obj.install(reset: reset)!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			if other_action.name == 'start' {
				console.print_debug('install action k3s.${other_action.name}')
				k8s_obj.start()!
			}
			if other_action.name == 'stop' {
				console.print_debug('install action k3s.${other_action.name}')
				k8s_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action k3s.${other_action.name}')
				k8s_obj.restart()!
			}
		}
		// K3s-specific actions
		if other_action.name in ['install_master', 'join_master', 'install_worker'] {
			if other_action.name == 'install_master' {
				console.print_debug('install action k3s.install_master')
				k8s_obj.install_master()!
			}
			if other_action.name == 'join_master' {
				console.print_debug('install action k3s.join_master')
				k8s_obj.join_master()!
			}
			if other_action.name == 'install_worker' {
				console.print_debug('install action k3s.install_worker')
				k8s_obj.install_worker()!
			}
		}
		if other_action.name == 'get_kubeconfig' {
			console.print_debug('install action k3s.get_kubeconfig')
			kubeconfig := k8s_obj.get_kubeconfig()!
			console.print_header('Kubeconfig:\n${kubeconfig}')
		}
		if other_action.name == 'generate_join_script' {
			console.print_debug('install action k3s.generate_join_script')
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
			console.print_debug("installer: k3s' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: k3s' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: k3s' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: k3s' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self K3s) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self K3s) start() ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('installer: k3s start')

	if !installed()! {
		return error('K3s is not installed. Please run install_master, join_master, or install_worker first.')
	}

	// Ensure data directory exists
	osal.dir_ensure(self.data_dir)!

	// Create manifests directory for auto-apply
	manifests_dir := '${self.data_dir}/server/manifests'
	osal.dir_ensure(manifests_dir)!

	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: k3s starting with ${zprocess.startuptype}...')

		sm.new(zprocess)!

		sm.start(zprocess.name)!
	}

	for _ in 0 .. 50 {
		if self.running()! {
			return
		}
		time.sleep(100 * time.millisecond)
	}
	return error('k3s did not start properly.')
}

pub fn (mut self K3s) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self K3s) stop() ! {
	switch(self.name)
	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
}

pub fn (mut self K3s) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self K3s) running() !bool {
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

pub fn (mut self K3s) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self K3s) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for k3s
pub fn switch(name string) {
	k3s_default = name
}
