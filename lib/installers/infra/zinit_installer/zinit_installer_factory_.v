module zinit_installer

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager
import time

__global (
	zinit_installer_global  map[string]&ZinitInstaller
	zinit_installer_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&ZinitInstaller {
	return &ZinitInstaller{}
}

pub fn get(args ArgsGet) !&ZinitInstaller {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'zinit_installer.') {
		return
	}
	mut install_actions := plbook.find(filter: 'zinit_installer.configure')!
	if install_actions.len > 0 {
		return error("can't configure zinit_installer:${args.name}, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'zinit_installer.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action zinit_installer.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action zinit_installer.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut zinit_installer_obj := get(name: name)!
			console.print_debug('action object:\n${zinit_installer_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action zinit_installer.${other_action.name}')
				zinit_installer_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action zinit_installer.${other_action.name}')
				zinit_installer_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action zinit_installer.${other_action.name}')
				zinit_installer_obj.restart()!
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
			console.print_debug("installer: zinit_installer' startupmanager get screen")
			return startupmanager.get(.screen)!
		}
		.zinit {
			console.print_debug("installer: zinit_installer' startupmanager get zinit")
			return startupmanager.get(.zinit)!
		}
		.systemd {
			console.print_debug("installer: zinit_installer' startupmanager get systemd")
			return startupmanager.get(.systemd)!
		}
		else {
			console.print_debug("installer: zinit_installer' startupmanager get auto")
			return startupmanager.get(.auto)!
		}
	}
}

pub fn (mut self ZinitInstaller) start() ! {
	if self.running()! {
		return
	}

	console.print_header('installer: zinit_installer start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('installer: zinit_installer starting with ${zprocess.startuptype}...')

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
	return error('zinit_installer did not install properly.')
}

pub fn (mut self ZinitInstaller) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self ZinitInstaller) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self ZinitInstaller) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self ZinitInstaller) running() !bool {
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

pub fn (mut self ZinitInstaller) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self ZinitInstaller) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self ZinitInstaller) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for zinit_installer
pub fn switch(name string) {
}
