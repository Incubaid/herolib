module redis

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	redis_global  map[string]&RedisInstall
	redis_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&RedisInstall {
	mut obj := RedisInstall{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&RedisInstall {
	mut context := base.context()!
	redis_default = args.name
	if args.fromdb || args.name !in redis_global {
		mut r := context.redis()!
		if r.hexists('context:redis', args.name)! {
			data := r.hget('context:redis', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('RedisInstall with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(RedisInstall, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("RedisInstall with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return redis_global[args.name] or {
		print_backtrace()
		return error('could not get config for redis with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o RedisInstall) ! {
	mut o2 := set_in_mem(o)!
	redis_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:redis', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:redis', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:redis', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&RedisInstall {
	mut res := []&RedisInstall{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		redis_global = map[string]&RedisInstall{}
		redis_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:redis')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in redis_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o RedisInstall) !RedisInstall {
	mut o2 := obj_init(o)!
	redis_global[o2.name] = &o2
	redis_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'redis.') {
		return
	}
	mut install_actions := plbook.find(filter: 'redis.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
	mut other_actions := plbook.find(filter: 'redis.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action redis.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action redis.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut redis_obj := get(name: name)!
			console.print_debug('action object:\n${redis_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action redis.${other_action.name}')
				redis_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action redis.${other_action.name}')
				redis_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action redis.${other_action.name}')
				redis_obj.restart()!
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
			console.print_debug("installer: redis' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: redis' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: redis' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: redis' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self RedisInstall) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self RedisInstall) start() ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('installer: redis start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: redis starting with ${zprocess.startuptype}...')

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
	return error('redis did not install properly.')
}

pub fn (mut self RedisInstall) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self RedisInstall) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self RedisInstall) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self RedisInstall) running() !bool {
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

pub fn (mut self RedisInstall) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self RedisInstall) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for redis
pub fn switch(name string) {
	redis_default = name
}
