module main

import os
import cli { Command }
import freeflowuniverse.herolib.core.herocmds
import freeflowuniverse.herolib.installers.base
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.ui
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.core.playcmds

fn playcmds_do(path string) ! {
	mut plbook := playbook.new(path: path)!
	playcmds.run(plbook: plbook)!
}

fn do() ! {
	if !core.is_osx()! {
		if os.getenv('SUDO_COMMAND') != '' || os.getenv('SUDO_USER') != '' {
			println('Error: Please do not run this program with sudo!')
			exit(1) // Exit with error code
		}
	}

	if os.getuid() == 0 {
		if core.is_osx()! {
			eprintln('please do not run hero as root in osx.')
			exit(1)
		}
	} else {
		if !core.is_osx()! {
			eprintln("please do run hero as root, don't use sudo.")
			exit(1)
		}
	}

	if os.args.len == 2 {
		mypath := os.args[1]
		if mypath.to_lower().ends_with('.hero') {
			// hero was called from a file
			playcmds_do(mypath)!
			return
		}
	}

	mut cmd := Command{
		name:        'hero'
		description: 'Your HERO toolset.'
		version:     '1.0.29'
	}

	// herocmds.cmd_run_add_flags(mut cmd)

	mut toinstall := false
	if !osal.cmd_exists('mc') || !osal.cmd_exists('redis-cli') {
		toinstall = true
	}

	if core.is_osx()! {
		if !osal.cmd_exists('brew') {
			console.clear()
			mut myui := ui.new()!
			toinstall = myui.ask_yesno(
				question: "we didn't find brew installed is it ok to install for you?"
				default:  true
			)!
			if toinstall {
				base.install()!
			}
			console.clear()
			console.print_stderr('Brew installed, please follow instructions and do hero ... again.')
			exit(0)
		}
	} else {
		if toinstall {
			base.install()!
		}
	}

	base.redis_install()!

	herocmds.cmd_run(mut cmd)
	herocmds.cmd_git(mut cmd)
	herocmds.cmd_generator(mut cmd)
	herocmds.cmd_docusaurus(mut cmd)
	herocmds.cmd_web(mut cmd)
	herocmds.cmd_sshagent(mut cmd)

	cmd.setup()
	cmd.parse(os.args)
}

fn main() {
	do() or {
		$dbg;
		eprintln('Error: ${err}')
		print_backtrace()
		exit(1)
	}
}

// fn pre_func(cmd Command) ! {
// 	herocmds.plbook_run(cmd)!
// }
