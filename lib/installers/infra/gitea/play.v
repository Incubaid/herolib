module gitea

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.installers.infra.gitea { install }

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'gitea.') {
		return
	}

	mut install_action := plbook.ensure_once(filter: 'gitea.install')!
	mut p := install_action.params

	mut args := InstallArgs{
		reset: p.get_default_false('reset')
	}

	console.print_header('Executing gitea.install action')
	install(args)!

	install_action.done = true
}
