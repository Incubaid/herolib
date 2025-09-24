module prometheus

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json
import freeflowuniverse.herolib.osal.startupmanager
import time

__global (
	prometheus_global  map[string]&Prometheus
	prometheus_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&Prometheus {
	return &Prometheus{}
}

pub fn get(args ArgsGet) !&Prometheus {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'prometheus.') {
		return
	}
	mut install_actions := plbook.find(filter: 'prometheus.configure')!
	if install_actions.len > 0 {
		return error("can't configure prometheus, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'prometheus.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action prometheus.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action prometheus.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut prometheus_obj := get(name: name)!
			console.print_debug('action object:\n${prometheus_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action prometheus.${other_action.name}')
				prometheus_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action prometheus.${other_action.name}')
				prometheus_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action prometheus.${other_action.name}')
				prometheus_obj.restart()!
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
			console.print_debug("installer: prometheus' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: prometheus' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: prometheus' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: prometheus' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

pub fn (mut self Prometheus) start() ! {
	if self.running()! {
		return
	}

	console.print_header('installer: prometheus start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: prometheus starting with ${zprocess.startuptype}...')

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
	return error('prometheus did not install properly.')
}

pub fn (mut self Prometheus) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self Prometheus) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self Prometheus) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self Prometheus) running() !bool {
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

pub fn (mut self Prometheus) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self Prometheus) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self Prometheus) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for prometheus
pub fn switch(name string) {
}
