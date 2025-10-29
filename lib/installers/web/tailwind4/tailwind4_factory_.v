module tailwind4

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager

__global (
	tailwind4_global  map[string]&Tailwind
	tailwind4_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&Tailwind {
	return &Tailwind{}
}

pub fn get(args ArgsGet) !&Tailwind {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'tailwind4.') {
		return
	}
	mut install_actions := plbook.find(filter: 'tailwind4.configure')!
	if install_actions.len > 0 {
		return error("can't configure tailwind4:${args.name}, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'tailwind4.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action tailwind4.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action tailwind4.install')
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

pub fn (mut self Tailwind) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self Tailwind) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for tailwind4
pub fn switch(name string) {
	tailwind4_default = name
}
