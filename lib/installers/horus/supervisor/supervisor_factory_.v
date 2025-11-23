module supervisor

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	supervisor_global  map[string]&Supervisor
	supervisor_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name        string = 'default'
	binary_path string
	redis_addr  string
	http_port   int
	ws_port     int
	log_level   string
	repo_path   string
	fromdb      bool // will load from filesystem
	create      bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&Supervisor {
	mut obj := Supervisor{
		name:        args.name
		binary_path: args.binary_path
		redis_addr:  args.redis_addr
		http_port:   args.http_port
		ws_port:     args.ws_port
		log_level:   args.log_level
		repo_path:   args.repo_path
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&Supervisor {
	mut context := base.context()!
	mut name := if args.name == 'default' && supervisor_default.len > 0 {
		supervisor_default
	} else {
		args.name
	}
	supervisor_default = name
	if args.fromdb || name !in supervisor_global {
		mut r := context.redis()!
		if r.hexists('context:supervisor', name)! {
			data := r.hget('context:supervisor', name)!
			if data.len == 0 {
				print_backtrace()
				return error('Supervisor with name: ${name} does not exist, prob bug.')
			}
			mut obj := json.decode(Supervisor, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("Supervisor with name '${name}' does not exist")
			}
		}
		return get(name: name)! // no longer from db nor create
	}
	return supervisor_global[name] or {
		print_backtrace()
		return error('could not get config for supervisor with name:${name}')
	}
}

// register the config for the future
pub fn set(o Supervisor) ! {
	mut o2 := set_in_mem(o)!
	supervisor_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:supervisor', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:supervisor', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:supervisor', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&Supervisor {
	mut res := []&Supervisor{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		supervisor_global = map[string]&Supervisor{}
		supervisor_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:supervisor')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in supervisor_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o Supervisor) !Supervisor {
	mut o2 := obj_init(o)!
	supervisor_global[o2.name] = &o2
	supervisor_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'supervisor.') {
		return
	}
	mut install_actions := plbook.find(filter: 'supervisor.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'supervisor.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build', 'start', 'stop', 'restart',
			'start_pre', 'start_post', 'stop_pre', 'stop_post'] {
			mut p := other_action.params
			name := p.get_default('name', 'default')!
			reset := p.get_default_false('reset')
			mut supervisor_obj := get(name: name, create: true)!
			console.print_debug('action object:\n${supervisor_obj}')

			if other_action.name == 'destroy' || reset {
				console.print_debug('install action supervisor.destroy')
				supervisor_obj.destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action supervisor.install')
				supervisor_obj.install(reset: reset)!
			}
			if other_action.name == 'build' {
				console.print_debug('install action supervisor.build')
				supervisor_obj.build()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart', 'start_pre', 'start_post', 'stop_pre',
			'stop_post'] {
			mut p := other_action.params
			name := p.get('name')!
			mut supervisor_obj := get(name: name, create: true)!
			console.print_debug('action object:\n${supervisor_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action supervisor.${other_action.name}')
				supervisor_obj.start()!
			}
			if other_action.name == 'stop' {
				console.print_debug('install action supervisor.${other_action.name}')
				supervisor_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action supervisor.${other_action.name}')
				supervisor_obj.restart()!
			}
			if other_action.name == 'start_pre' {
				console.print_debug('install action supervisor.${other_action.name}')
				supervisor_obj.start_pre()!
			}
			if other_action.name == 'start_post' {
				console.print_debug('install action supervisor.${other_action.name}')
				supervisor_obj.start_post()!
			}
			if other_action.name == 'stop_pre' {
				console.print_debug('install action supervisor.${other_action.name}')
				supervisor_obj.stop_pre()!
			}
			if other_action.name == 'stop_post' {
				console.print_debug('install action supervisor.${other_action.name}')
				supervisor_obj.stop_post()!
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
			console.print_debug("installer: supervisor' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: supervisor' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: supervisor' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: supervisor' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self Supervisor) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self Supervisor) start() ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('installer: supervisor start')

	if !self.installed()! {
		self.install()!
	}

	self.configure()!

	self.start_pre()!

	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: supervisor starting with ${zprocess.startuptype}...')

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
	return error('supervisor did not install properly.')
}

pub fn (mut self Supervisor) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self Supervisor) stop() ! {
	switch(self.name)
	self.stop_pre()!
	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	self.stop_post()!
}

pub fn (mut self Supervisor) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self Supervisor) running() !bool {
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

// switch instance to be used for supervisor
pub fn switch(name string) {
	supervisor_default = name
}
