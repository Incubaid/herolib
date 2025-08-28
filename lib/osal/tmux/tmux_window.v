module tmux

import os
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.data.ourtime
import time
import freeflowuniverse.herolib.ui.console

@[heap]
struct Window {
pub mut:
	session &Session @[skip]
	name    string
	id      int
	panes   []&Pane // windows contain multiple panes
	active  bool
	env     map[string]string
}

@[params]
pub struct PaneNewArgs {
pub mut:
	name  string
	reset bool // means we reset the pane if it already exists
	cmd   string
	env   map[string]string
}

pub fn (mut w Window) scan() ! {
	// Get current panes for this window
	cmd := "tmux list-panes -t ${w.session.name}:@${w.id} -F '#{pane_id}|#{pane_pid}|#{pane_active}|#{pane_start_command}'"
	result := osal.execute_silent(cmd) or {
		// Window might not exist anymore
		return
	}

	mut current_panes := map[int]bool{}
	for line in result.split_into_lines() {
		if line.contains('|') {
			parts := line.split('|')
			if parts.len >= 3 {
				pane_id := parts[0].replace('%', '').int()
				pane_pid := parts[1].int()
				pane_active := parts[2] == '1'
				pane_cmd := if parts.len > 3 { parts[3] } else { '' }

				current_panes[pane_id] = true

				// Update existing pane or create new one
				mut found := false
				for mut p in w.panes {
					if p.id == pane_id {
						p.pid = pane_pid
						p.active = pane_active
						p.cmd = pane_cmd
						found = true
						break
					}
				}

				if !found {
					mut new_pane := Pane{
						window:             &w
						id:                 pane_id
						pid:                pane_pid
						active:             pane_active
						cmd:                pane_cmd
						env:                map[string]string{}
						created_at:         time.now()
						last_output_offset: 0
					}
					w.panes << &new_pane
				}
			}
		}
	}

	// Remove panes that no longer exist
	w.panes = w.panes.filter(current_panes[it.id] == true)
}

pub fn (mut w Window) stop() ! {
	w.kill()!
}

// helper function
// TODO env variables are not inserted in pane
pub fn (mut w Window) create(cmd_ string) ! {
	mut final_cmd := cmd_
	if cmd_.contains('\n') {
		os.mkdir_all('/tmp/tmux/${w.session.name}')!
		// Fix: osal.exec_string doesn't exist, use file writing instead
		script_path := '/tmp/tmux/${w.session.name}/${w.name}.sh'
		script_content := '#!/bin/bash\n' + cmd_
		os.write_file(script_path, script_content)!
		os.chmod(script_path, 0o755)!
		final_cmd = script_path
	}

	mut newcmd := '/bin/bash -c "${final_cmd}"'
	if cmd_ == '' {
		newcmd = '/bin/bash'
	}

	// Build environment arguments
	mut env_args := ''
	for key, value in w.env {
		env_args += ' -e ${key}="${value}"'
	}

	res_opt := "-P -F '#{session_name}|#{window_name}|#{window_id}|#{pane_active}|#{pane_id}|#{pane_pid}|#{pane_start_command}'"
	cmd := 'tmux new-window ${res_opt}${env_args} -t ${w.session.name} -n ${w.name} \'${newcmd}\''
	console.print_debug(cmd)

	res := osal.exec(cmd: cmd, stdout: false, name: 'tmux_window_create') or {
		return error("Can't create new window ${w.name} \n${cmd}\n${err}")
	}

	line_arr := res.output.split('|')
	wid := line_arr[2] or { return error('cannot split line for window create.\n${line_arr}') }
	w.id = wid.replace('@', '').int()
}

// stop the window
pub fn (mut w Window) kill() ! {
	osal.exec(
		cmd:    'tmux kill-window -t @${w.id}'
		stdout: false
		name:   'tmux_kill-window'
		// die:    false
	) or { return error("Can't kill window with id:${w.id}: ${err}") }
	w.active = false // Window is no longer active
}

pub fn (window Window) str() string {
	mut out := ' - name:${window.name} wid:${window.id} active:${window.active}'
	for pane in window.panes {
		out += '\n    ${*pane}'
	}
	return out
}

pub fn (mut w Window) stats() !ProcessStats {
	mut total := ProcessStats{}
	for mut pane in w.panes {
		stats := pane.stats() or { continue }
		total.cpu_percent += stats.cpu_percent
		total.memory_bytes += stats.memory_bytes
		total.memory_percent += stats.memory_percent
	}
	return total
}

// will select the current window so with tmux a we can go there .
// to login into a session do `tmux a -s mysessionname`
fn (mut w Window) activate() ! {
	cmd2 := 'tmux select-window -t @${w.id}'
	osal.execute_silent(cmd2) or {
		return error("Couldn't select window ${w.name} \n${cmd2}\n${err}")
	}
}

// List panes in a window
pub fn (mut w Window) pane_list() []&Pane {
	return w.panes
}

// Get active pane in window
pub fn (mut w Window) pane_active() ?&Pane {
	for pane in w.panes {
		if pane.active {
			return pane
		}
	}
	return none
}

@[params]
pub struct PaneSplitArgs {
pub mut:
	cmd        string            // command to run in new pane
	horizontal bool              // true for horizontal split, false for vertical
	env        map[string]string // environment variables
}

// Split the active pane horizontally or vertically
pub fn (mut w Window) pane_split(args PaneSplitArgs) !&Pane {
	mut cmd_to_run := args.cmd
	if cmd_to_run == '' {
		cmd_to_run = '/bin/bash'
	}

	// Build environment arguments
	mut env_args := ''
	for key, value in args.env {
		env_args += ' -e ${key}="${value}"'
	}

	// Choose split direction
	split_flag := if args.horizontal { '-h' } else { '-v' }

	// Execute tmux split-window command
	res_opt := "-P -F '#{session_name}|#{window_name}|#{window_id}|#{pane_active}|#{pane_id}|#{pane_pid}|#{pane_start_command}'"
	cmd := 'tmux split-window ${split_flag} ${res_opt}${env_args} -t ${w.session.name}:@${w.id} \'${cmd_to_run}\''

	console.print_debug('Splitting pane: ${cmd}')

	res := osal.exec(cmd: cmd, stdout: false, name: 'tmux_pane_split') or {
		return error("Can't split pane in window ${w.name}: ${err}")
	}

	// Parse the result to get new pane info
	line_arr := res.output.split('|')
	if line_arr.len < 7 {
		return error('Invalid tmux split-window output: ${res.output}')
	}

	pane_id := line_arr[4].replace('%', '').int()
	pane_pid := line_arr[5].int()
	pane_active := line_arr[3] == '1'
	pane_cmd := line_arr[6] or { '' }

	// Create new pane object
	mut new_pane := Pane{
		window:             &w
		id:                 pane_id
		pid:                pane_pid
		active:             pane_active
		cmd:                pane_cmd
		env:                args.env
		created_at:         time.now()
		last_output_offset: 0
	}

	// Add to window's panes and rescan to get current state
	w.panes << &new_pane
	w.scan()!

	// Return reference to the new pane
	for mut pane in w.panes {
		if pane.id == pane_id {
			return pane
		}
	}

	return error('Could not find newly created pane with ID ${pane_id}')
}

// Split pane horizontally (side by side)
pub fn (mut w Window) pane_split_horizontal(cmd string) !&Pane {
	return w.pane_split(cmd: cmd, horizontal: true)
}

// Split pane vertically (top and bottom)
pub fn (mut w Window) pane_split_vertical(cmd string) !&Pane {
	return w.pane_split(cmd: cmd, horizontal: false)
}

@[params]
pub struct TtydArgs {
pub mut:
	port     int
	editable bool // if true, allows write access to the terminal
}

// Run ttyd for this window so it can be accessed in the browser
pub fn (mut w Window) run_ttyd(args TtydArgs) ! {
	target := '${w.session.name}:@${w.id}'

	// Add -W flag for write access if editable mode is enabled
	mut ttyd_flags := '-p ${args.port}'
	if args.editable {
		ttyd_flags += ' -W'
	}

	cmd := 'nohup ttyd ${ttyd_flags} tmux attach -t ${target} >/dev/null 2>&1 &'

	code := os.system(cmd)
	if code != 0 {
		return error('Failed to start ttyd on port ${args.port} for window ${w.name}')
	}

	mode_str := if args.editable { 'editable' } else { 'read-only' }
	println('ttyd started for window ${w.name} at http://localhost:${args.port} (${mode_str} mode)')
}

// Backward compatibility method - runs ttyd in read-only mode
pub fn (mut w Window) run_ttyd_readonly(port int) ! {
	w.run_ttyd(port: port, editable: false)!
}
