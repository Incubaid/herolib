module salrunner

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	salrunner_global  map[string]&Salrunner
	salrunner_default string
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

pub fn new(args ArgsGet) !&Salrunner {
	mut obj := Salrunner{
		name:        args.name
		binary_path: args.binary_path
		redis_addr:  args.redis_addr
		log_level:   args.log_level
		repo_path:   args.repo_path
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&Salrunner {
	mut context := base.context()!
	salrunner_default = args.name
	if args.fromdb || args.name !in salrunner_global {
		mut r := context.redis()!
		if r.hexists('context:salrunner', args.name)! {
			data := r.hget('context:salrunner', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('Salrunner with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(Salrunner, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("Salrunner with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return salrunner_global[args.name] or {
		print_backtrace()
		return error('could not get config for salrunner with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o Salrunner) ! {
	mut o2 := set_in_mem(o)!
	salrunner_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:salrunner', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:salrunner', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:salrunner', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&Salrunner {
	mut res := []&Salrunner{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		salrunner_global = map[string]&Salrunner{}
		salrunner_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:salrunner')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in salrunner_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o Salrunner) !Salrunner {
	mut o2 := obj_init(o)!
	salrunner_global[o2.name] = &o2
	salrunner_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'salrunner.') {
		return
	}
	mut install_actions := plbook.find(filter: 'salrunner.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'salrunner.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build', 'start', 'stop', 'restart',
			'start_pre', 'start_post', 'stop_pre', 'stop_post'] {
			mut p := other_action.params
			name := p.get_default('name', 'default')!
			reset := p.get_default_false('reset')
			mut salrunner_obj := get(name: name, create: true)!
			console.print_debug('action object:\n${salrunner_obj}')

			if other_action.name == 'destroy' || reset {
				console.print_debug('install action salrunner.destroy')
				salrunner_obj.destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action salrunner.install')
				salrunner_obj.install(reset: reset)!
			}
			if other_action.name == 'build' {
				console.print_debug('install action salrunner.build')
				salrunner_obj.build()!
			}
			if other_action.name == 'start' {
				console.print_debug('install action salrunner.${other_action.name}')
				salrunner_obj.start(reset: reset)!
			}
			if other_action.name == 'stop' {
				console.print_debug('install action salrunner.${other_action.name}')
				salrunner_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action salrunner.${other_action.name}')
				salrunner_obj.restart(reset: reset)!
			}
			if other_action.name == 'start_pre' {
				console.print_debug('install action salrunner.${other_action.name}')
				salrunner_obj.start_pre()!
			}
			if other_action.name == 'start_post' {
				console.print_debug('install action salrunner.${other_action.name}')
				salrunner_obj.start_post()!
			}
			if other_action.name == 'stop_pre' {
				console.print_debug('install action salrunner.${other_action.name}')
				salrunner_obj.stop_pre()!
			}
			if other_action.name == 'stop_post' {
				console.print_debug('install action salrunner.${other_action.name}')
				salrunner_obj.stop_post()!
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
			console.print_debug("installer: salrunner' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: salrunner' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: salrunner' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: salrunner' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self Salrunner) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self Salrunner) start(args StartArgs) ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('installer: salrunner start')

	if !self.installed()! {
		self.install()!
	}

	self.start_pre()!

	for zprocess in self.startupcmd(args)! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: salrunner starting with ${zprocess.startuptype}...')

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
	return error('salrunner did not install properly.')
}

pub fn (mut self Salrunner) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start(reset: false)!
}

pub fn (mut self Salrunner) stop() ! {
	switch(self.name)
	self.stop_pre()!
	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	self.stop_post()!
}

pub fn (mut self Salrunner) restart(args StartArgs) ! {
	switch(self.name)
	self.stop()!
	self.start(args)!
}

pub fn (mut self Salrunner) running() !bool {
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

// switch instance to be used for salrunner
pub fn switch(name string) {
	salrunner_default = name
}
