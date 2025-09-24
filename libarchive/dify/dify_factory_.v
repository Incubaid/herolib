module dify

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json
import freeflowuniverse.herolib.osal.startupmanager
import time

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&DifyInstaller {
	mut obj := DifyInstaller{
		name: args.name
	}
	set(obj)!
	return &obj
}

pub fn get(args ArgsGet) !&DifyInstaller {
	mut context := base.context()!
	dify_default = args.name
	if args.fromdb || args.name !in dify_global {
		mut r := context.redis()!
		if r.hexists('context:dify', args.name)! {
			data := r.hget('context:dify', args.name)!
			if data.len == 0 {
				return error('DifyInstaller with name: dify does not exist, prob bug.')
			}
			mut obj := json.decode(DifyInstaller, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				return error("DifyInstaller with name 'dify' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return dify_global[args.name] or {
		return error('could not get config for dify with name:dify')
	}
}

// register the config for the future
pub fn set(o DifyInstaller) ! {
	set_in_mem(o)!
	dify_default = o.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:dify', o.name, json.encode(o))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:dify', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:dify', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&DifyInstaller {
	mut res := []&DifyInstaller{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		dify_global = map[string]&DifyInstaller{}
		dify_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:dify')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in dify_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o DifyInstaller) ! {
	mut o2 := obj_init(o)!
	dify_global[o.name] = &o2
	dify_default = o.name
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'dify.') {
		return
	}
	mut install_actions := plbook.find(filter: 'dify.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
		}
	}
	mut other_actions := plbook.find(filter: 'dify.')!
	for other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action dify.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action dify.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut dify_obj := get(name: name)!
			console.print_debug('action object:\n${dify_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action dify.${other_action.name}')
				dify_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action dify.${other_action.name}')
				dify_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action dify.${other_action.name}')
				dify_obj.restart()!
			}
		}
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
			console.print_debug('startupmanager: zinit')
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug('startupmanager: zinit')
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug('startupmanager: systemd')
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug('startupmanager: auto')
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self DifyInstaller) reload() ! {
	self = obj_init(self)!
}

pub fn (mut self DifyInstaller) start() ! {
	if self.running()! {
		return
	}

	console.print_header('dify start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('starting dify with ${zprocess.startuptype}...')

		sm.new(zprocess)!

		sm.start(zprocess.name)!
	}

	start_post()!

	for _ in 0 .. 50 {
		if self.running()! {
			return
		}
		time.sleep(100 * time.millisecond)
	}
	return error('dify did not install properly.')
}

pub fn (mut self DifyInstaller) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self DifyInstaller) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self DifyInstaller) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self DifyInstaller) running() !bool {
	switch(self.name)

	// walk over the generic processes, if not running return
	for zprocess in startupcmd()! {
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

pub fn (mut self DifyInstaller) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self DifyInstaller) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self DifyInstaller) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for dify
pub fn switch(name string) {
}
