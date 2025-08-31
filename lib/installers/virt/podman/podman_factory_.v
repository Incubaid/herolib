module podman

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import json
import freeflowuniverse.herolib.osal.startupmanager

__global (
	podman_global  map[string]&PodmanInstaller
	podman_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&PodmanInstaller {
	return &PodmanInstaller{}
}

pub fn get(args ArgsGet) !&PodmanInstaller {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'podman.') {
		return
	}
	mut install_actions := plbook.find(filter: 'podman.configure')!
	if install_actions.len > 0 {
		return error("can't configure podman, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'podman.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action podman.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action podman.install')
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

pub fn (mut self PodmanInstaller) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self PodmanInstaller) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for podman
pub fn switch(name string) {
}
