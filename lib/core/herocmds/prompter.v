module herocmds

import incubaid.herolib.web.heroprompt
import os
import cli { Command, Flag }
import time

pub fn cmd_prompter(mut cmdroot Command) Command {
	mut cmd_run := Command{
		name:          'prompter'
		description:   'Run the HeroPrompt code context tool for LLM prompts.'
		required_args: 0
		execute:       cmd_prompter_execute
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
		description: 'Host to bind the server to (default: localhost).'
	})

	cmd_run.add_flag(Flag{
		flag:        .int
		required:    false
		name:        'port'
		abbrev:      'p'
		description: 'Port to bind the server to (default: 8888).'
	})

	cmdroot.add_command(cmd_run)
	return cmdroot
}

fn cmd_prompter_execute(cmd Command) ! {
	// ---------- FLAGS ----------
	mut open_ := cmd.flags.get_bool('open') or { false }
	mut host := cmd.flags.get_string('host') or { 'localhost' }
	mut port := cmd.flags.get_int('port') or { 8888 }

	// Set defaults if not provided
	if host == '' {
		host = 'localhost'
	}
	if port == 0 {
		port = 8888
	}

	args := heroprompt.ServerArgs{
		title: 'HeroPrompt'
		host:  host
		port:  port
		open:  open_
	}

	spawn fn [args] () {
		heroprompt.start(args) or { return }
	}()

	time.sleep(1 * time.second)
	url := 'http://${args.host}:${args.port}'

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
			if result.exit_code != 0 {
				return error('Failed to open browser: ${result.output}')
			}
		}
	}

	// Keep the process alive while the server runs
	for {
		time.sleep(1 * time.second)
	}
}

