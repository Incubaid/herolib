module traefik

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json
import freeflowuniverse.herolib.osal.startupmanager
import time

__global (
	traefik_global  map[string]&TraefikServer
	traefik_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&TraefikServer {
	mut obj := TraefikServer{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&TraefikServer {
	mut context := base.context()!
	traefik_default = args.name
	if args.fromdb || args.name !in traefik_global {
		mut r := context.redis()!
		if r.hexists('context:traefik', args.name)! {
			data := r.hget('context:traefik', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('TraefikServer with name: traefik does not exist, prob bug.')
			}
			mut obj := json.decode(TraefikServer, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("TraefikServer with name 'traefik' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return traefik_global[args.name] or {
		print_backtrace()
		return error('could not get config for traefik with name:traefik')
	}
}

// register the config for the future
pub fn set(o TraefikServer) ! {
	mut o2 := set_in_mem(o)!
	traefik_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:traefik', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:traefik', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:traefik', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&TraefikServer {
	mut res := []&TraefikServer{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		traefik_global = map[string]&TraefikServer{}
		traefik_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:traefik')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in traefik_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o TraefikServer) !TraefikServer {
	mut o2 := obj_init(o)!
	traefik_global[o2.name] = &o2
	traefik_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'traefik.') {
		return
	}
	mut install_actions := plbook.find(filter: 'traefik.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'traefik.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action traefik.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action traefik.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut traefik_obj := get(name: name)!
			console.print_debug('action object:\n${traefik_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action traefik.${other_action.name}')
				traefik_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action traefik.${other_action.name}')
				traefik_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action traefik.${other_action.name}')
				traefik_obj.restart()!
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
			console.print_debug("installer: traefik' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: traefik' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: traefik' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: traefik' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self TraefikServer) reload() ! {
	self = obj_init(self)!
}

pub fn (mut self TraefikServer) start() ! {
	if self.running()! {
		return
	}

	console.print_header('installer: traefik start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: traefik starting with ${zprocess.startuptype}...')

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
	return error('traefik did not install properly.')
}

pub fn (mut self TraefikServer) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self TraefikServer) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self TraefikServer) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self TraefikServer) running() !bool {
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

pub fn (mut self TraefikServer) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self TraefikServer) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for traefik
pub fn switch(name string) {
}
