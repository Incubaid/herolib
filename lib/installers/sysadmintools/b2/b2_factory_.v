module b2

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager

__global (
	b2_global  map[string]&BackBase
	b2_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&BackBase {
	return &BackBase{}
}

pub fn get(args ArgsGet) !&BackBase {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'b2.') {
		return
	}
	mut install_actions := plbook.find(filter: 'b2.configure')!
	if install_actions.len > 0 {
		return error("can't configure b2:${args.name}, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'b2.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action b2.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action b2.install')
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

pub fn (mut self BackBase) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self BackBase) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for b2
pub fn switch(name string) {
}
