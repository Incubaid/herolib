module herocmds

import incubaid.herolib.ui.console
import incubaid.herolib.core.playcmds
import os
import cli { Command, Flag }

pub fn cmd_run(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'run'
		description:   'Run heroscript from inline string or file'
		usage:         '
Run HeroScript

USAGE:
  hero run [flags] [file]
  hero run -s "heroscript content"

EXAMPLES:
  # Run from file
  hero run script.heroscript
  hero run examples/virt/heropods/demo.heroscript

  # Run inline heroscript
  hero run -s "!!heropods.configure name:\'demo\' reset:false use_podman:true"

  # Run multi-line heroscript
  hero run -s "
  !!heropods.configure
      name:\'demo\'
      reset:false
      use_podman:true

  !!heropods.container_new
      name:\'demo_container\'
      image:\'alpine_3_20\'
  "
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
	return error('No heroscript provided. Use -s for inline script or provide a file path.\n\n${cmd.help_message()}')
}

