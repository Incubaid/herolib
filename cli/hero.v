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

// do_update handles the update command without requiring Redis
fn do_update() ! {
	// Parse flags manually since we're not using the CLI framework
	use_dev := '--dev' in os.args || '-d' in os.args

	script_url := if use_dev {
		'https://raw.githubusercontent.com/incubaid/herolib/refs/heads/development/scripts/install_hero.sh'
	} else {
		'https://raw.githubusercontent.com/incubaid/herolib/refs/heads/main/scripts/install_hero.sh'
	}

	branch := if use_dev { 'development' } else { 'main' }
	println('🔄 Updating hero from ${branch} branch...')

	result := os.execute('curl -sL ${script_url} | bash')
	if result.exit_code != 0 {
		return error('Failed to update hero: ${result.output}')
	}
	println(result.output)
}

fn do() ! {
	// Handle 'update' command early, before Redis initialization
	// This allows updating hero in environments without Redis
	if os.args.len >= 2 && os.args[1] == 'update' {
		do_update()!
		return
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
		version:     '1.0.42'
	}

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
	herocmds.cmd_atlas(mut cmd)
	herocmds.cmd_source(mut cmd)
	herocmds.cmd_update(mut cmd)

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