module herocmds

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.web.ui
import os
import cli { Command, Flag }
import time

pub fn cmd_web(mut cmdroot Command) Command {
	mut cmd_run := Command{
		name:          'web'
		description:   'Run the Heroprompt UI (located in lib/web/heroprompt).'
		required_args: 0
		execute:       cmd_web_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'open'
		abbrev:      'o'
		description: 'Open the UI in the default browser after starting the server.'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'host'
		abbrev:      'h'
		description: 'Host to bind the server to (default: localhost).'
	})

	cmd_run.add_flag(Flag{
		flag:        .int
		required:    false
		name:        'port'
		abbrev:      'p'
		description: 'Port to bind the server to (default: 8080).'
	})

	cmdroot.add_command(cmd_run)
	return cmdroot
}

fn cmd_web_execute(cmd Command) ! {
	// ---------- FLAGS ----------
	mut open_ := cmd.flags.get_bool('open') or { false }
	mut host := cmd.flags.get_string('host') or { 'localhost' }
	mut port := cmd.flags.get_int('port') or { 8080 }

	// Set defaults if not provided
	if host == '' {
		host = 'localhost'
	}
	if port == 0 {
		port = 8080
	}

	console.print_header('Starting Heroprompt...')

	// Prepare arguments for the UI factory
	mut factory_args := ui.FactoryArgs{
		title: 'Hero Admin Panel'
		host:  host
		port:  port
	}

	// ---------- START WEB SERVER ----------
	console.print_header('Starting Heroprompt server...')

	// Start the server in a separate thread to allow for browser opening
	spawn fn [factory_args] () {
		ui.start(factory_args) or {
			console.print_stderr('Failed to start Heroprompt server: ${err}')
			return
		}
	}()

	// Give the server a moment to start
	time.sleep(2 * time.second)
	url := 'http://${factory_args.host}:${factory_args.port}'

	console.print_green('Heroprompt server is running on ${url}')

	if open_ {
		mut cmd_str := ''
		$if macos {
			cmd_str = 'open ${url}'
		} $else $if linux {
			cmd_str = 'xdg-open ${url}'
		} $else $if windows {
			cmd_str = 'start ${url}'
		}

		if cmd_str != '' {
			result := os.execute(cmd_str)
			if result.exit_code == 0 {
				console.print_green('Opened Heroprompt in default browser.')
			} else {
				console.print_stderr('Failed to open browser: ${result.output}')
			}
		}
	}

	// Keep the process alive while the server runs
	console.print_header('Press Ctrl+C to stop the server')
	for {
		time.sleep(1 * time.second)
	}
}
