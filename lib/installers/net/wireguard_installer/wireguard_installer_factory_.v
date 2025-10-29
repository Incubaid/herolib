module wireguard_installer

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager

__global (
	wireguard_installer_global  map[string]&WireGuard
	wireguard_installer_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&WireGuard {
	return &WireGuard{}
}

pub fn get(args ArgsGet) !&WireGuard {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'wireguard_installer.') {
		return
	}
	mut install_actions := plbook.find(filter: 'wireguard_installer.configure')!
	if install_actions.len > 0 {
		return error("can't configure wireguard_installer:${args.name}, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'wireguard_installer.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action wireguard_installer.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action wireguard_installer.install')
				install()!
			}
		}
		other_action.done = true
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////# LIVE CYCLE MANAGEMENT FOR INSTALLERS ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

pub fn (mut self WireGuard) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self WireGuard) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for wireguard_installer
pub fn switch(name string) {
	wireguard_installer_default = name
}
