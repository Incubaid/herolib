module coredns

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.installers.infra.coredns { install }

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'coredns.') {
		return
	}

	mut install_action := plbook.ensure_once(filter: 'coredns.install')!
	mut p := install_action.params

	mut args := InstallArgs{
		reset: p.get_default_false('reset')
	}

	console.print_header('Executing coredns.install action')
	install(args)!

	install_action.done = true
}