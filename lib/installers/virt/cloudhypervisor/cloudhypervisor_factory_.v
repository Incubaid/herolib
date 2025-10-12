module cloudhypervisor

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager

__global (
	cloudhypervisor_global  map[string]&CloudHypervisor
	cloudhypervisor_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&CloudHypervisor {
	return &CloudHypervisor{}
}

pub fn get(args ArgsGet) !&CloudHypervisor {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'cloudhypervisor.') {
		return
	}
	mut install_actions := plbook.find(filter: 'cloudhypervisor.configure')!
	if install_actions.len > 0 {
		return error("can't configure cloudhypervisor, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'cloudhypervisor.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action cloudhypervisor.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action cloudhypervisor.install')
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

pub fn (mut self CloudHypervisor) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self CloudHypervisor) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self CloudHypervisor) destroy() ! {
	switch(self.name)
	destroy()!
}

// switch instance to be used for cloudhypervisor
pub fn switch(name string) {
}
