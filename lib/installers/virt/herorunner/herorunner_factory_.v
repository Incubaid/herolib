module herorunner

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager

__global (
	herorunner_global  map[string]&HeroRunner
	herorunner_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&HeroRunner {
	return &HeroRunner{}
}

pub fn get(args ArgsGet) !&HeroRunner {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'herorunner.') {
		return
	}
	mut install_actions := plbook.find(filter: 'herorunner.configure')!
	if install_actions.len > 0 {
		return error("can't configure herorunner, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'herorunner.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action herorunner.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action herorunner.install')
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

pub fn (mut self HeroRunner) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self HeroRunner) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for herorunner
pub fn switch(name string) {
	herorunner_default = name
}
