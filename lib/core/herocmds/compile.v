module herocmds

import os
import incubaid.herolib.ui.console
import incubaid.herolib.develop.gittools
import incubaid.herolib.osal.core as osal
import cli { Command, Flag }

pub fn cmd_compile(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'compile'
		usage:         'hero compile [--reset]'
		description:   'Pull herolib and compile hero binary'
		required_args: 0
		execute:       cmd_compile_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'reset'
		abbrev:      'r'
		description: 'Reset herolib repo before pulling (discard local changes)'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'pull'
		abbrev:      'p'
		description: 'Pull latest changes (default: true)'
		default_value: ['true']
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_compile_execute(cmd Command) ! {
	reset := cmd.flags.get_bool('reset') or { false }
	pull := cmd.flags.get_bool('pull') or { true }

	console.print_header('🔨 Hero Compile')

	// Get herolib repo
	mut gs := gittools.new()!
	
	console.print_item('Fetching herolib...')
	repo := gs.get_repo(
		url:   'https://github.com/incubaid/herolib'
		pull:  pull
		reset: reset
	)!

	herolib_path := repo.path()
	cli_path := '${herolib_path}/cli'

	console.print_item('Compiling hero...')
	
	// Run compile.vsh
	osal.exec(
		cmd: './compile.vsh'
		work_folder: cli_path
	)!

	console.print_green('✅ Hero compiled successfully')
	
	// Show version
	result := os.execute('hero -version')
	if result.exit_code == 0 {
		console.print_item('Version: ${result.output.trim_space()}')
	}
}
