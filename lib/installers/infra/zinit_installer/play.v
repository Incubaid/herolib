module zinit_installer

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.installers.infra.zinit_installer { install }

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'zinit_installer.') {
		return
	}

	mut install_action := plbook.ensure_once(filter: 'zinit_installer.install')!
	mut p := install_action.params

	mut args := InstallArgs{
		reset: p.get_default_false('reset')
	}

	console.print_header('Executing zinit_installer.install action')
	install(args)!

	install_action.done = true
}