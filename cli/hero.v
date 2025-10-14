module main

import os
import cli { Command }
import incubaid.herolib.core.herocmds
import incubaid.herolib.installers.base
import incubaid.herolib.ui.console
import incubaid.herolib.ui
import incubaid.herolib.osal.core as osal
import incubaid.herolib.core
import incubaid.herolib.core.playbook
import incubaid.herolib.core.playcmds

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
		if mypath == '.' {
			playcmds_do(os.getwd())!
			return
		}
		if mypath.to_lower().ends_with('.hero') || mypath.to_lower().ends_with('.heroscript')
			|| mypath.to_lower().ends_with('.hs') {
			// hero was called from a file
			playcmds_do(mypath)!
			return
		}
	}

	mut cmd := Command{
		name:        'hero'
		description: 'Your HERO toolset.'
		version:     '1.0.35'
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
		// $dbg;
		eprintln('Error: ${err}')
		print_backtrace()
		exit(1)
	}
}