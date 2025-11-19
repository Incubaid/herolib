module osirisrunner

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	osirisrunner_global  map[string]&Osirisrunner
	osirisrunner_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name        string = 'default'
	binary_path string
	redis_addr  string
	log_level   string
	repo_path   string
	fromdb      bool // will load from filesystem
	create      bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&Osirisrunner {
	mut obj := Osirisrunner{
		name:        args.name
		binary_path: args.binary_path
		redis_addr:  args.redis_addr
		log_level:   args.log_level
		repo_path:   args.repo_path
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&Osirisrunner {
	mut context := base.context()!
	osirisrunner_default = args.name
	if args.fromdb || args.name !in osirisrunner_global {
		mut r := context.redis()!
		if r.hexists('context:osirisrunner', args.name)! {
			data := r.hget('context:osirisrunner', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('Osirisrunner with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(Osirisrunner, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("Osirisrunner with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return osirisrunner_global[args.name] or {
		print_backtrace()
		return error('could not get config for osirisrunner with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o Osirisrunner) ! {
	mut o2 := set_in_mem(o)!
	osirisrunner_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:osirisrunner', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:osirisrunner', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:osirisrunner', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&Osirisrunner {
	mut res := []&Osirisrunner{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		osirisrunner_global = map[string]&Osirisrunner{}
		osirisrunner_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:osirisrunner')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in osirisrunner_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o Osirisrunner) !Osirisrunner {
	mut o2 := obj_init(o)!
	osirisrunner_global[o2.name] = &o2
	osirisrunner_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'osirisrunner.') {
		return
	}
	mut install_actions := plbook.find(filter: 'osirisrunner.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'osirisrunner.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build', 'start', 'stop', 'restart', 'start_pre', 'start_post', 'stop_pre', 'stop_post'] {
			mut p := other_action.params
			name := p.get_default('name', 'default')!
			reset := p.get_default_false('reset')
			mut osirisrunner_obj := get(name: name)!
			console.print_debug('action object:\n${osirisrunner_obj}')
			
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action osirisrunner.destroy')
				osirisrunner_obj.destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action osirisrunner.install')
				osirisrunner_obj.install(reset: reset)!
			}
			if other_action.name == 'build' {
				console.print_debug('install action osirisrunner.build')
				osirisrunner_obj.build()!
			}
			if other_action.name == 'start' {
				console.print_debug('install action osirisrunner.${other_action.name}')
				osirisrunner_obj.start()!
			}
			if other_action.name == 'stop' {
				console.print_debug('install action osirisrunner.${other_action.name}')
				osirisrunner_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action osirisrunner.${other_action.name}')
				osirisrunner_obj.restart()!
			}
			if other_action.name == 'start_pre' {
				console.print_debug('install action osirisrunner.${other_action.name}')
				osirisrunner_obj.start_pre()!
			}
			if other_action.name == 'start_post' {
				console.print_debug('install action osirisrunner.${other_action.name}')
				osirisrunner_obj.start_post()!
			}
			if other_action.name == 'stop_pre' {
				console.print_debug('install action osirisrunner.${other_action.name}')
				osirisrunner_obj.stop_pre()!
			}
			if other_action.name == 'stop_post' {
				console.print_debug('install action osirisrunner.${other_action.name}')
				osirisrunner_obj.stop_post()!
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
			console.print_debug("installer: osirisrunner' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: osirisrunner' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: osirisrunner' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: osirisrunner' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self Osirisrunner) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self Osirisrunner) start() ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('installer: osirisrunner start')

	if !self.installed()! {
		self.install()!
	}

	self.start_pre()!

	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: osirisrunner starting with ${zprocess.startuptype}...')

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
	return error('osirisrunner did not install properly.')
}

pub fn (mut self Osirisrunner) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self Osirisrunner) stop() ! {
	switch(self.name)
	self.stop_pre()!
	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	self.stop_post()!
}

pub fn (mut self Osirisrunner) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self Osirisrunner) running() !bool {
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

// switch instance to be used for osirisrunner
pub fn switch(name string) {
	osirisrunner_default = name
}
