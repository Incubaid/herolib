module base

import incubaid.herolib.core.playbook
import incubaid.herolib.ui.console

pub fn play(mut plbook playbook.PlayBook) ! {
	if plbook.exists(filter: 'base.install') {
		console.print_header('play base.install')
		for mut action in plbook.find(filter: 'base.install')! {
			mut p := action.params
			install(
				reset:   p.get_default_false('reset')
				develop: p.get_default_false('develop')
			)!
			action.done = true
		}
	}
	if plbook.exists(filter: 'base.develop') {
		console.print_header('play base.develop')
		for mut action in plbook.find(filter: 'base.develop')! {
			mut p := action.params
			develop(
				reset: p.get_default_false('reset')
			)!
			action.done = true
		}
	}
	if plbook.exists(filter: 'base.redis_install') {
		console.print_header('play base.redis_install')
		for action in plbook.find(filter: 'base.redis_install')! {
			mut p := action.params
			redis_install(
				port:   p.get_int_default('port', 6379)!
				ipaddr: p.get_default('ipaddr', 'localhost')!
				reset:  p.get_default_false('reset')
				start:  p.get_default_true('start')
			)!
		}
	}
	// if plbook.exists(filter: 'base.sshkeysinstall') {
	// 	console.print_header('play base.sshkeysinstall')
	// 	for action in plbook.find(filter: 'base.sshkeysinstall')! {
	// 		mut p := action.params
	// 		sshkeysinstall(
	// 			reset: p.get_default_false('reset')
	// 		)!
	// 	}
	// }
}
