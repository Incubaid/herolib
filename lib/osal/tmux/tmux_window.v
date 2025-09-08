module tmux

import os
import freeflowuniverse.herolib.osal.core as osal
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
		line_trimmed := line.trim_space()
		if line_trimmed.len == 0 {
			continue
		}
		if line_trimmed.contains('|') {
			parts := line_trimmed.split('|')
			if parts.len >= 3 && parts[0].len > 0 && parts[1].len > 0 {
				// Safely parse pane ID
				pane_id_str := parts[0].replace('%', '').trim_space()
				if pane_id_str.len == 0 {
					continue
				}
				pane_id := pane_id_str.int()

				// Safely parse PID
				pane_pid_str := parts[1].trim_space()
				if pane_pid_str.len == 0 {
					continue
				}
				pane_pid := pane_pid_str.int()

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
	mut valid_panes := []&Pane{}
	for pane in w.panes {
		// Use safe map access with 'in' operator first
		if pane.id in current_panes && current_panes[pane.id] == true {
			valid_panes << pane
		}
	}
	w.panes = valid_panes
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

// stop the window with comprehensive process cleanup
pub fn (mut w Window) kill() ! {
	// First, kill all processes in all panes of this window
	w.kill_all_processes()!

	// Then kill the tmux window itself
	osal.exec(
		cmd:    'tmux kill-window -t @${w.id}'
		stdout: false
		name:   'tmux_kill-window'
		// die:    false
	) or { return error("Can't kill window with id:${w.id}: ${err}") }
	w.active = false // Window is no longer active
}

// Kill all processes in all panes of this window
pub fn (mut w Window) kill_all_processes() ! {
	console.print_debug('Killing all processes in window ${w.name} (ID: ${w.id})')

	// Refresh pane information to get current state
	w.scan()!

	// Kill processes in each pane
	for mut pane in w.panes {
		pane.kill_processes() or {
			console.print_debug('Failed to kill processes in pane %${pane.id}: ${err}')
			// Continue with other panes even if one fails
		}
	}
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
	// Logging parameters
	log      bool   // enable logging for this pane
	logreset bool   // reset/clear existing logs when enabling
	logpath  string // custom log path, if empty uses default
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
		// Initialize logging fields
		log_enabled: false
		log_path:    ''
		logger_pid:  0
	}

	// Add to window's panes and rescan to get current state
	w.panes << &new_pane
	w.scan()!

	// Enable logging if requested
	if args.log {
		new_pane.logging_enable(
			logpath:  args.logpath
			logreset: args.logreset
		) or {
			console.print_debug('Warning: Failed to enable logging for pane %${new_pane.id}: ${err}')
		}
	}

	// Return the new pane reference
	return &new_pane
}

// Split pane horizontally (side by side)
pub fn (mut w Window) pane_split_horizontal(cmd string) !&Pane {
	return w.pane_split(cmd: cmd, horizontal: true)
}

// Split pane vertically (top and bottom)
pub fn (mut w Window) pane_split_vertical(cmd string) !&Pane {
	return w.pane_split(cmd: cmd, horizontal: false)
}

// Resize panes to equal dimensions dynamically based on pane count
pub fn (mut w Window) resize_panes_equal() ! {
	w.scan()! // Refresh pane information

	pane_count := w.panes.len
	if pane_count <= 1 {
		return
	}

	// Dynamic layout based on actual pane count
	match pane_count {
		1 {
			// Single pane, no resizing needed
			console.print_debug('Single pane, no resizing needed')
		}
		2 {
			// Two panes: use even-horizontal layout (side by side)
			cmd := 'tmux select-layout -t ${w.session.name}:@${w.id} even-horizontal'
			osal.execute_silent(cmd) or {
				console.print_debug('Could not apply even-horizontal layout: ${err}')
			}
		}
		3 {
			// Three panes: use main-horizontal layout (one large top, two smaller bottom)
			cmd := 'tmux select-layout -t ${w.session.name}:@${w.id} main-horizontal'
			osal.execute_silent(cmd) or {
				console.print_debug('Could not apply main-horizontal layout: ${err}')
			}
		}
		4 {
			// Four panes: use tiled layout (2x2 grid)
			cmd := 'tmux select-layout -t ${w.session.name}:@${w.id} tiled'
			osal.execute_silent(cmd) or {
				console.print_debug('Could not apply tiled layout: ${err}')
			}
		}
		else {
			// For 5+ panes: use tiled layout which works well for any number
			if pane_count >= 5 {
				cmd := 'tmux select-layout -t ${w.session.name}:@${w.id} tiled'
				osal.execute_silent(cmd) or {
					console.print_debug('Could not apply tiled layout for ${pane_count} panes: ${err}')
				}
			}
		}
	}
}

@[params]
pub struct TtydArgs {
pub mut:
	port     int
	editable bool // if true, allows write access to the terminal
}

// Run ttyd for this window so it can be accessed in the browser
pub fn (mut w Window) run_ttyd(args TtydArgs) ! {
	// Check if the port is available before starting ttyd
	osal.port_check_available(args.port) or {
		return error('Cannot start ttyd for window ${w.name}: ${err}')
	}

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

// Stop ttyd for this window by killing the process on the specified port
pub fn (mut w Window) stop_ttyd(port int) ! {
	// Kill any process running on the specified port
	cmd := 'lsof -ti:${port} | xargs kill -9'
	osal.execute_silent(cmd) or {
		// Ignore error if no process is found on the port
		// This is normal when no ttyd is running on that port
	}
	println('ttyd stopped for window ${w.name} on port ${port} (if it was running)')
}

// Get a pane by its ID
pub fn (mut w Window) pane_get(id int) !&Pane {
	w.scan()! // refresh info from tmux
	for pane in w.panes {
		if pane.id == id {
			return pane
		}
	}
	return error('Pane with id ${id} not found in window ${w.name}. Available panes: ${w.panes}')
}

// Create a new pane (just a split with default shell)
pub fn (mut w Window) pane_new() !&Pane {
	return w.pane_split(
		cmd:        '/bin/bash'
		horizontal: true
	)
}
