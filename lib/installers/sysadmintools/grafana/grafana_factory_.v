module grafana

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	grafana_global  map[string]&Grafana
	grafana_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&Grafana {
	return &Grafana{}
}

pub fn get(args ArgsGet) !&Grafana {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'grafana.') {
		return
	}
	mut install_actions := plbook.find(filter: 'grafana.configure')!
	if install_actions.len > 0 {
		return error("can't configure grafana, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'grafana.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action grafana.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action grafana.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut grafana_obj := get(name: name)!
			console.print_debug('action object:\n${grafana_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action grafana.${other_action.name}')
				grafana_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action grafana.${other_action.name}')
				grafana_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action grafana.${other_action.name}')
				grafana_obj.restart()!
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
			console.print_debug("installer: grafana' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: grafana' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: grafana' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: grafana' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

pub fn (mut self Grafana) start() ! {
	if self.running()! {
		return
	}

	console.print_header('installer: grafana start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: grafana starting with ${zprocess.startuptype}...')

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
	return error('grafana did not install properly.')
}

pub fn (mut self Grafana) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self Grafana) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self Grafana) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self Grafana) running() !bool {
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

pub fn (mut self Grafana) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self Grafana) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self Grafana) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for grafana
pub fn switch(name string) {
}
