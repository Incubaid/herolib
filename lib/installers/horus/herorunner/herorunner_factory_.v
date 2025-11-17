module herorunner

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	herorunner_global  map[string]&HerorunnerServer
	herorunner_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name        string = 'default'
	binary_path string
	redis_addr  string
	log_level   string
	fromdb      bool // will load from filesystem
	create      bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&HerorunnerServer {
	mut obj := HerorunnerServer{
		name:        args.name
		binary_path: args.binary_path
		redis_addr:  args.redis_addr
		log_level:   args.log_level
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&HerorunnerServer {
	mut context := base.context()!
	herorunner_default = args.name
	if args.fromdb || args.name !in herorunner_global {
		mut r := context.redis()!
		if r.hexists('context:herorunner', args.name)! {
			data := r.hget('context:herorunner', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('HerorunnerServer with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(HerorunnerServer, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("HerorunnerServer with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return herorunner_global[args.name] or {
		print_backtrace()
		return error('could not get config for herorunner with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o HerorunnerServer) ! {
	mut o2 := set_in_mem(o)!
	herorunner_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:herorunner', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:herorunner', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:herorunner', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&HerorunnerServer {
	mut res := []&HerorunnerServer{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		herorunner_global = map[string]&HerorunnerServer{}
		herorunner_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:herorunner')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in herorunner_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o HerorunnerServer) !HerorunnerServer {
	mut o2 := obj_init(o)!
	herorunner_global[o2.name] = &o2
	herorunner_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'herorunner.') {
		return
	}
	mut install_actions := plbook.find(filter: 'herorunner.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'herorunner.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action herorunner.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action herorunner.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut herorunner_obj := get(name: name)!
			console.print_debug('action object:\n${herorunner_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action herorunner.${other_action.name}')
				herorunner_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action herorunner.${other_action.name}')
				herorunner_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action herorunner.${other_action.name}')
				herorunner_obj.restart()!
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
			console.print_debug("installer: herorunner' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: herorunner' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: herorunner' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: herorunner' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self HerorunnerServer) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self HerorunnerServer) start() ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('installer: herorunner start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: herorunner starting with ${zprocess.startuptype}...')

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
	return error('herorunner did not install properly.')
}

pub fn (mut self HerorunnerServer) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self HerorunnerServer) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self HerorunnerServer) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self HerorunnerServer) running() !bool {
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

pub fn (mut self HerorunnerServer) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self HerorunnerServer) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self HerorunnerServer) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for herorunner
pub fn switch(name string) {
	herorunner_default = name
}
