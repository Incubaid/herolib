module herocmds

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
  hero update                      # Update from development branch (default)
  hero update --branch main        # Update from main branch

OPTIONS:
  --branch, -b  Branch to install from (default: development)
  --force, -f   Force reinstall even if already on latest version
'
		execute:       cmd_update_execute
		sort_commands: true
	}

	cmd_run.add_flag(Flag{
		flag:        .string
		name:        'branch'
		abbrev:      'b'
		description: 'Branch to install from (default: development)'
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
	branch := cmd.flags.get_string('branch') or { 'development' }
	is_script := cmd.flags.get_bool('script') or { false }

	if !is_script {
		console.print_header('🔄 Hero Update')
		console.print_debug('Updating from ${branch} branch...')
	}

	// Use correct GitHub raw URL format (no refs/heads/)
	script_url := 'https://raw.githubusercontent.com/incubaid/herolib/${branch}/scripts/install_hero.sh'

	// Download using osal.download (no Redis dependency)
	script_path := osal.download(
		url:        script_url
		dest:       '/tmp/install_hero.sh'
		reset:      true
		minsize_kb: 1
	) or {
		return error('Failed to download install script. Branch "${branch}" may not exist.\nURL: ${script_url}')
	}

	// Execute the install script
	osal.exec(cmd: 'bash ${script_path.path}', stdout: true)!

	if !is_script {
		console.print_green('✅ Hero updated successfully')
	}
}
