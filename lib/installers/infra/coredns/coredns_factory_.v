module coredns

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json
import freeflowuniverse.herolib.osal.startupmanager
import time

__global (
	coredns_global  map[string]&CoreDNS
	coredns_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&CoreDNS {
	mut obj := CoreDNS{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&CoreDNS {
	mut context := base.context()!
	coredns_default = args.name
	if args.fromdb || args.name !in coredns_global {
		mut r := context.redis()!
		if r.hexists('context:coredns', args.name)! {
			data := r.hget('context:coredns', args.name)!
			if data.len == 0 {
				return error('CoreDNS with name: coredns does not exist, prob bug.')
			}
			mut obj := json.decode(CoreDNS, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				return error("CoreDNS with name 'coredns' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return coredns_global[args.name] or {
		return error('could not get config for coredns with name:coredns')
	}
}

// register the config for the future
pub fn set(o CoreDNS) ! {
	mut o2 := set_in_mem(o)!
	coredns_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:coredns', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:coredns', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:coredns', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&CoreDNS {
	mut res := []&CoreDNS{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		coredns_global = map[string]&CoreDNS{}
		coredns_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:coredns')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in coredns_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o CoreDNS) !CoreDNS {
	mut o2 := obj_init(o)!
	coredns_global[o2.name] = &o2
	coredns_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'coredns.') {
		return
	}
	mut install_actions := plbook.find(filter: 'coredns.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
		}
	}
	mut other_actions := plbook.find(filter: 'coredns.')!
	for other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action coredns.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action coredns.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut coredns_obj := get(name: name)!
			console.print_debug('action object:\n${coredns_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action coredns.${other_action.name}')
				coredns_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action coredns.${other_action.name}')
				coredns_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action coredns.${other_action.name}')
				coredns_obj.restart()!
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
			console.print_debug('startupmanager: screen')
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
pub fn (mut self CoreDNS) reload() ! {
	self = obj_init(self)!
}

pub fn (mut self CoreDNS) start() ! {
	if self.running()! {
		return
	}

	console.print_header('coredns start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('starting coredns with ${zprocess.startuptype}...')

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
	return error('coredns did not install properly.')
}

pub fn (mut self CoreDNS) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self CoreDNS) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self CoreDNS) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self CoreDNS) running() !bool {
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

pub fn (mut self CoreDNS) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self CoreDNS) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self CoreDNS) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for coredns
pub fn switch(name string) {
}
