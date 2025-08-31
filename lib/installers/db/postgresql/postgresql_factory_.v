module postgresql

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json
import freeflowuniverse.herolib.osal.startupmanager
import time

__global (
	postgresql_global  map[string]&Postgresql
	postgresql_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&Postgresql {
	mut obj := Postgresql{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&Postgresql {
	mut context := base.context()!
	postgresql_default = args.name
	if args.fromdb || args.name !in postgresql_global {
		mut r := context.redis()!
		if r.hexists('context:postgresql', args.name)! {
			data := r.hget('context:postgresql', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('Postgresql with name: postgresql does not exist, prob bug.')
			}
			mut obj := json.decode(Postgresql, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("Postgresql with name 'postgresql' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return postgresql_global[args.name] or {
		print_backtrace()
		return error('could not get config for postgresql with name:postgresql')
	}
}

// register the config for the future
pub fn set(o Postgresql) ! {
	mut o2 := set_in_mem(o)!
	postgresql_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:postgresql', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:postgresql', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:postgresql', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&Postgresql {
	mut res := []&Postgresql{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		postgresql_global = map[string]&Postgresql{}
		postgresql_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:postgresql')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in postgresql_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o Postgresql) !Postgresql {
	mut o2 := obj_init(o)!
	postgresql_global[o2.name] = &o2
	postgresql_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'postgresql.') {
		return
	}
	mut install_actions := plbook.find(filter: 'postgresql.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'postgresql.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action postgresql.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action postgresql.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut postgresql_obj := get(name: name)!
			console.print_debug('action object:\n${postgresql_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action postgresql.${other_action.name}')
				postgresql_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action postgresql.${other_action.name}')
				postgresql_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action postgresql.${other_action.name}')
				postgresql_obj.restart()!
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
			console.print_debug("installer: postgresql' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: postgresql' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: postgresql' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: postgresql' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self Postgresql) reload() ! {
	self = obj_init(self)!
}

pub fn (mut self Postgresql) start() ! {
	if self.running()! {
		return
	}

	console.print_header('installer: postgresql start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: postgresql starting with ${zprocess.startuptype}...')

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
	return error('postgresql did not install properly.')
}

pub fn (mut self Postgresql) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self Postgresql) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self Postgresql) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self Postgresql) running() !bool {
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

pub fn (mut self Postgresql) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self Postgresql) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for postgresql
pub fn switch(name string) {
}
