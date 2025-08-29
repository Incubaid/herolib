module vlang

import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.ui.console

pub fn play(mut plbook playbook.PlayBook) ! {
	if plbook.exists(filter: 'vlang.install') {
		console.print_header('play vlang.install')
		for mut action in plbook.find(filter: 'vlang.install')! {
			mut p := action.params
			install(
				reset: p.get_default_false('reset')
			)!
			action.done = true
		}
	}
	if plbook.exists(filter: 'vlang.v_analyzer_install') {
		console.print_header('play vlang.v_analyzer_install')
		for mut action in plbook.find(filter: 'vlang.v_analyzer_install')! {
			mut p := action.params
			v_analyzer_install(
				reset: p.get_default_false('reset')
			)!
			action.done = true
		}
	}
}
