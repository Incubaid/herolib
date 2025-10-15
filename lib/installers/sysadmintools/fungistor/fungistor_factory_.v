module fungistor

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	fungistor_global  map[string]&FungiStor
	fungistor_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&FungiStor {
	return &FungiStor{}
}

pub fn get(args ArgsGet) !&FungiStor {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'fungistor.') {
		return
	}
	mut install_actions := plbook.find(filter: 'fungistor.configure')!
	if install_actions.len > 0 {
		return error("can't configure fungistor, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'fungistor.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action fungistor.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action fungistor.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut fungistor_obj := get(name: name)!
			console.print_debug('action object:\n${fungistor_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action fungistor.${other_action.name}')
				fungistor_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action fungistor.${other_action.name}')
				fungistor_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action fungistor.${other_action.name}')
				fungistor_obj.restart()!
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
			console.print_debug("installer: fungistor' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: fungistor' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: fungistor' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: fungistor' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

pub fn (mut self FungiStor) start() ! {
	if self.running()! {
		return
	}

	console.print_header('installer: fungistor start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: fungistor starting with ${zprocess.startuptype}...')

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
	return error('fungistor did not install properly.')
}

pub fn (mut self FungiStor) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self FungiStor) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self FungiStor) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self FungiStor) running() !bool {
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

pub fn (mut self FungiStor) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self FungiStor) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self FungiStor) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for fungistor
pub fn switch(name string) {
}
