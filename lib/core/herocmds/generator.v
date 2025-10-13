module herocmds

import incubaid.herolib.core.generator.generic
import os
import cli { Command, Flag }

pub fn cmd_generator(mut cmdroot Command) {
	mut cmd_run := Command{
		name:        'generate'
		description: 'generator for vlang code in hero context.\narg is path (required). Use "." for current directory.'
		// required_args: 1
		execute: cmd_generator_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'reset'
		abbrev:      'r'
		description: 'will reset.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'force'
		abbrev:      'f'
		description: 'will work non interactive if possible.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'playonly'
		description: 'generate the play script.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'scan'
		abbrev:      's'
		description: 'scanning operation, walk over directories.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'installer'
		abbrev:      'i'
		description: 'Make sure its installer.'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_generator_execute(cmd Command) ! {
	mut force := cmd.flags.get_bool('force') or { false }
	mut reset := cmd.flags.get_bool('reset') or { false }
	mut scan := cmd.flags.get_bool('scan') or { false }
	mut playonly := cmd.flags.get_bool('playonly') or { false }
	mut installer := cmd.flags.get_bool('installer') or { false }

	// Get path from required argument
	mut path := ''

	if cmd.args.len > 0 {
		path = cmd.args[0]
	}

	if playonly {
		force = true
	}

	// Handle "." as current working directory
	if path == '.' {
		path = os.getwd()
	} else {
		// Expand home directory
		path = path.replace('~', os.home_dir())

		// Validate that path exists
		if !os.exists(path) {
			return error('Path does not exist: ${path}')
		}
	}

	mut cat := generic.Cat.client
	if installer {
		cat = generic.Cat.installer
	}

	if scan {
		generic.scan(path: path, reset: reset, force: force, cat: cat, playonly: playonly)!
	} else {
		generic.generate(path: path, reset: reset, force: force, cat: cat)!
	}
}
