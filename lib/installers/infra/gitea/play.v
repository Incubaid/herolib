module gitea

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import incubaid.herolib.installers.infra.gitea { install }

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
