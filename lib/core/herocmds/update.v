module herocmds

import os
import incubaid.herolib.ui.console
import incubaid.herolib.osal.core as osal
import cli { Command, Flag }

pub fn cmd_update(mut cmdroot Command) {
	mut cmd_run := Command{
		name:        'update'
		description: 'Update hero to the latest version.'
		usage:       '
Hero Update - Self-update to latest version

Downloads and installs the latest hero binary from GitHub releases.

USAGE:
  hero update [options]

EXAMPLES:
  hero update           # Update to latest release
  hero update --dev     # Update from development branch

OPTIONS:
  --dev, -d    Install from development branch instead of latest release
  --force, -f  Force reinstall even if already on latest version
'
		execute:       cmd_update_execute
		sort_commands: true
	}

	cmd_run.add_flag(Flag{
		flag:        .bool
		name:        'dev'
		abbrev:      'd'
		description: 'Install from development branch instead of latest release'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		name:        'force'
		abbrev:      'f'
		description: 'Force reinstall even if already on latest version'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		name:        'script'
		abbrev:      's'
		description: 'Run in script/non-interactive mode'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_update_execute(cmd Command) ! {
	use_dev := cmd.flags.get_bool('dev') or { false }
	is_script := cmd.flags.get_bool('script') or { false }

	if !is_script {
		console.print_header('🔄 Hero Update')
	}

	// Determine install script URL
	script_url := if use_dev {
		'https://raw.githubusercontent.com/incubaid/herolib/refs/heads/development/scripts/install_hero.sh'
	} else {
		'https://raw.githubusercontent.com/incubaid/herolib/refs/heads/main/scripts/install_hero.sh'
	}

	if !is_script {
		branch := if use_dev { 'development' } else { 'main' }
		console.print_debug('Updating from ${branch} branch...')
	}

	// Download and execute install script
	result := osal.exec(
		cmd: 'curl -sL ${script_url} | bash'
		stdout: true
	) or {
		return error('Failed to update hero: ${err}')
	}

	if !is_script {
		console.print_green('✅ Hero updated successfully')
	}
}
