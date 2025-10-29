module golang

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager

__global (
	golang_global  map[string]&GolangInstaller
	golang_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&GolangInstaller {
	return &GolangInstaller{}
}

pub fn get(args ArgsGet) !&GolangInstaller {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'golang.') {
		return
	}
	mut install_actions := plbook.find(filter: 'golang.configure')!
	if install_actions.len > 0 {
		return error("can't configure golang, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'golang.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action golang.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action golang.install')
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

pub fn (mut self GolangInstaller) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self GolangInstaller) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self GolangInstaller) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for golang
pub fn switch(name string) {
}
