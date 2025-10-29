module livekit

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	livekit_global  map[string]&LivekitServer
	livekit_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&LivekitServer {
	mut obj := LivekitServer{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&LivekitServer {
	mut context := base.context()!
	livekit_default = args.name
	if args.fromdb || args.name !in livekit_global {
		mut r := context.redis()!
		if r.hexists('context:livekit', args.name)! {
			data := r.hget('context:livekit', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('LivekitServer with name: livekit does not exist, prob bug.')
			}
			mut obj := json.decode(LivekitServer, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("LivekitServer with name 'livekit' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return livekit_global[args.name] or {
		print_backtrace()
		return error('could not get config for livekit with name:livekit')
	}
}

// register the config for the future
pub fn set(o LivekitServer) ! {
	mut o2 := set_in_mem(o)!
	livekit_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:livekit', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:livekit', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:livekit', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&LivekitServer {
	mut res := []&LivekitServer{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		livekit_global = map[string]&LivekitServer{}
		livekit_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:livekit')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in livekit_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o LivekitServer) !LivekitServer {
	mut o2 := obj_init(o)!
	livekit_global[o2.name] = &o2
	livekit_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'livekit.') {
		return
	}
	mut install_actions := plbook.find(filter: 'livekit.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'livekit.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action livekit.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action livekit.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut livekit_obj := get(name: name)!
			console.print_debug('action object:\n${livekit_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action livekit.${other_action.name}')
				livekit_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action livekit.${other_action.name}')
				livekit_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action livekit.${other_action.name}')
				livekit_obj.restart()!
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
			console.print_debug("installer: livekit' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: livekit' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: livekit' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: livekit' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self LivekitServer) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self LivekitServer) start() ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('installer: livekit start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: livekit starting with ${zprocess.startuptype}...')

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
	return error('livekit did not install properly.')
}

pub fn (mut self LivekitServer) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self LivekitServer) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self LivekitServer) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self LivekitServer) running() !bool {
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

pub fn (mut self LivekitServer) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self LivekitServer) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for livekit
pub fn switch(name string) {
	livekit_default = name
}
