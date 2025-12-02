module kubectl

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json
import incubaid.herolib.osal.startupmanager

__global (
	kubectl_global  map[string]&Kubectl
	kubectl_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

pub fn new(args ArgsGet) !&Kubectl {
	return &Kubectl{}
}

pub fn get(args ArgsGet) !&Kubectl {
	return new(args)!
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'kubectl.') {
		return
	}
	mut install_actions := plbook.find(filter: 'kubectl.configure')!
	if install_actions.len > 0 {
		return error("can't configure kubectl, because no configuration allowed for this installer.")
	}
	mut other_actions := plbook.find(filter: 'kubectl.')!
	for mut other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			name := p.get_default('name', 'default')!
			reset := p.get_default_false('reset')
			mut kubectl_obj := get(name: name)!
			console.print_debug('action object:\n${kubectl_obj}')

			if other_action.name == 'destroy' || reset {
				console.print_debug('install action kubectl.destroy')
				kubectl_obj.destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action kubectl.install')
				kubectl_obj.install(reset: reset)!
			}
			if other_action.name == 'build' {
				console.print_debug('install action kubectl.build')
				kubectl_obj.build()!
			}
		}
		other_action.done = true
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////# LIVE CYCLE MANAGEMENT FOR INSTALLERS ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

// switch instance to be used for kubectl
pub fn switch(name string) {
	kubectl_default = name
}
