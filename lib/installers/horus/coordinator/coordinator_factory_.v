module coordinator

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	coordinator_global  map[string]&CoordinatorServer
	coordinator_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name        string = 'coordinator'
	binary_path string
	redis_addr  string
	http_port   int
	ws_port     int
	log_level   string
	repo_path   string
	fromdb      bool // will load from filesystem
	create      bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&CoordinatorServer {
	mut obj := CoordinatorServer{
		name:        args.name
		binary_path: args.binary_path
		redis_addr:  args.redis_addr
		http_port:   args.http_port
		ws_port:     args.ws_port
		log_level:   args.log_level
		repo_path:   args.repo_path
	}

	// Try to set in Redis, if it fails (Redis not available), use in-memory config
	set(obj) or {
		console.print_debug('Redis not available, using in-memory configuration')
		set_in_mem(obj)!
	}

	return get(name: args.name)!
}

pub fn get(args_ ArgsGet) !&CoordinatorServer {
	mut args := args_
	mut context := base.context()!
	if args.name == 'coordinator' && coordinator_default != '' {
		args.name = coordinator_default
	}
	if args.fromdb || args.name !in coordinator_global {
		mut r := context.redis()!
		if r.hexists('context:coordinator', args.name)! {
			data := r.hget('context:coordinator', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('CoordinatorServer with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(CoordinatorServer, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("CoordinatorServer with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return coordinator_global[args.name] or {
		print_backtrace()
		return error('could not get config for coordinator with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o CoordinatorServer) ! {
	mut o2 := set_in_mem(o)!
	coordinator_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:coordinator', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:coordinator', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:coordinator', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&CoordinatorServer {
	mut res := []&CoordinatorServer{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		coordinator_global = map[string]&CoordinatorServer{}
		coordinator_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:coordinator')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in coordinator_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o CoordinatorServer) !CoordinatorServer {
	mut o2 := obj_init(o)!
	coordinator_global[o2.name] = &o2
	coordinator_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'coordinator.') {
		return
	}
	mut install_actions := plbook.find(filter: 'coordinator.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'coordinator.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action coordinator.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action coordinator.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut coordinator_obj := get(name: name)!
			console.print_debug('action object:\n${coordinator_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action coordinator.${other_action.name}')
				coordinator_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action coordinator.${other_action.name}')
				coordinator_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action coordinator.${other_action.name}')
				coordinator_obj.restart()!
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
			console.print_debug("installer: coordinator' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: coordinator' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: coordinator' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			// default to zinit
			console.print_debug("installer: coordinator' startupmanager get auto")
			return startupmanager.get(.zinit)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self CoordinatorServer) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self CoordinatorServer) start() ! {
	switch(self.name)

	if self.running()! {
		return
	}

	console.print_header('installer: coordinator start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: coordinator starting with ${zprocess.startuptype}...')

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
	return error('coordinator did not install properly.')
}

pub fn (mut self CoordinatorServer) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self CoordinatorServer) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self CoordinatorServer) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self CoordinatorServer) running() !bool {
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

pub fn (mut self CoordinatorServer) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self CoordinatorServer) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self CoordinatorServer) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for coordinator
pub fn switch(name string) {
	coordinator_default = name
}
