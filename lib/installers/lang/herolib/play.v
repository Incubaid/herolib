module herolib

import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.ui.console

pub fn play(mut plbook playbook.PlayBook) ! {
	if ! plbook.exists(filter: 'herolib.') {
		return
	}
	if plbook.exists(filter: 'herolib.uninstall') {
		console.print_header('play herolib.uninstall')
		for mut action in plbook.find(filter: 'herolib.uninstall')! {
			uninstall()!
			action.done = true
			break
		}
		
	}
	if plbook.exists(filter: 'herolib.install') {
		console.print_header('play herolib.install')
		for mut action in plbook.find(filter: 'herolib.install')! {
			mut p := action.params
			install(
				reset: p.get_default_false('reset')

			)!
			action.done = true
			break
		}
	}
	if plbook.exists(filter: 'herolib.compile') {
		console.print_header('play herolib.compile')
		for mut action in plbook.find(filter: 'herolib.compile')! {
			mut p := action.params
			compile(
				reset: p.get_default_false('reset')
				git_pull: p.get_default_false('git_pull')
				git_reset: p.get_default_false('git_reset')
			)!
			action.done = true
			break
		}
	}
}