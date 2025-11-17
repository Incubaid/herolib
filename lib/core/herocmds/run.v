module herocmds

import incubaid.herolib.ui.console
import incubaid.herolib.core.playcmds
import os
import cli { Command, Flag }

pub fn cmd_run(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'run'
		description:   'Run heroscript from inline string, file path, or URL'
		usage:         '
Run HeroScript

USAGE:
  hero run [file]                           Run heroscript from file path (positional argument)
  hero run -s "heroscript content"          Run inline heroscript
  hero run -p /path/to/script.hero          Run heroscript from file path
  hero run -u https://example.com/script    Run heroscript from URL (currently disabled)
'
		required_args: 0
		execute:       cmd_run_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'script'
		abbrev:      's'
		description: 'Inline heroscript to execute'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'path'
		abbrev:      'p'
		description: 'Path to heroscript to execute'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'reset'
		abbrev:      'r'
		description: 'Reset before running'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_run_execute(cmd Command) ! {
	mut reset := cmd.flags.get_bool('reset') or { false }
	mut inline_script := cmd.flags.get_string('script') or { '' }
	// mut url := cmd.flags.get_string('url') or { '' }
	mut path_flag := cmd.flags.get_string('path') or { '' }

	// Count how many input methods are being used
	mut input_count := 0
	if inline_script != '' {
		input_count++
	}

	if path_flag != '' {
		input_count++
	}

	if cmd.args.len > 0 {
		input_count++
	}

	// Validate that only one input method is used
	if input_count > 1 {
		return error('Error: Multiple input methods specified. Please use only one of: -s (inline script), -p (file path), or positional file argument.\n\n${cmd.help_message()}')
	}

	// If inline script is provided via -s flag
	if inline_script != '' {
		console.print_header('Running inline heroscript...')

		// Create a temporary file to hold the heroscript
		temp_dir := os.temp_dir()
		temp_file := '${temp_dir}/hero_inline_${os.getpid()}.heroscript'

		// Write the inline script to temp file
		os.write_file(temp_file, inline_script) or {
			return error('Failed to write temporary heroscript file: ${err}')
		}
		// Ensure cleanup
		defer {
			os.rm(temp_file) or {}
		}
		// Run the heroscript
		playcmds.run(heroscript_path: temp_file, reset: reset)!
		return
	}

	// If path is provided via -p flag
	if path_flag != '' {
		mut path := path_flag

		// Handle "." as current working directory
		if path == '.' {
			path = os.getwd()
		} else {
			// Expand home directory
			path = path.replace('~', os.home_dir())
			// Validate that path exists
			if !os.exists(path) {
				return error('File does not exist: ${path}')
			}
		}

		console.print_header('Running heroscript from file: ${path}')
		playcmds.run(heroscript_path: path, reset: reset)!
		return
	}

	// If file path is provided as argument
	if cmd.args.len > 0 {
		mut path := cmd.args[0]

		// Handle "." as current working directory
		if path == '.' {
			path = os.getwd()
		} else {
			// Expand home directory
			path = path.replace('~', os.home_dir())

			// Validate that path exists
			if !os.exists(path) {
				return error('File does not exist: ${path}')
			}
		}

		console.print_header('Running heroscript from file: ${path}')
		playcmds.run(heroscript_path: path, reset: reset)!
		return
	}

	// No script provided
	return error('Error: No heroscript provided.\n\nPlease specify a heroscript using one of these methods:\n  -s "script"           Inline heroscript content\n  -p /path/to/file      Path to heroscript file\n  [file]                File path as positional argument\n\n${cmd.help_message()}')
}
