module tmux

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.texttools
import os
import freeflowuniverse.herolib.ui.console

@[heap]
struct Session {
pub mut:
	tmux    &Tmux @[str: skip] // reference back
	windows []&Window // session has windows
	name    string
}

@[params]
pub struct WindowArgs {
pub mut:
	name  string
	cmd   string
	env   map[string]string
	reset bool
}

@[params]
pub struct WindowGetArgs {
pub mut:
	name string
	id   int
}

pub fn (mut s Session) create() ! {
	// Check if session already exists
	cmd_check := 'tmux has-session -t ${s.name}'
	check_result := osal.exec(cmd: cmd_check, stdout: false, ignore_error: true) or {
		// Session doesn't exist, this is expected
		osal.Job{}
	}

	if check_result.exit_code == 0 {
		return error('duplicate session: ${s.name}')
	}

	// Create new session
	cmd := 'tmux new-session -d -s ${s.name}'
	osal.exec(cmd: cmd, stdout: false, name: 'tmux_session_create') or {
		return error("Can't create session ${s.name}: ${err}")
	}
}

// load info from reality
pub fn (mut s Session) scan() ! {
	// Get current windows from tmux for this session
	cmd := "tmux list-windows -t ${s.name} -F '#{window_name}|#{window_id}|#{window_active}'"
	result := osal.execute_silent(cmd) or {
		if err.msg().contains('session not found') {
			return
		}
		return error('Cannot list windows for session ${s.name}: ${err}')
	}

	mut current_windows := map[string]bool{}
	for line in result.split_into_lines() {
		line_trimmed := line.trim_space()
		if line_trimmed.len == 0 {
			continue
		}
		if line_trimmed.contains('|') {
			parts := line_trimmed.split('|')
			if parts.len >= 3 && parts[0].len > 0 && parts[1].len > 0 {
				// Safely extract window name with additional validation
				raw_window_name := parts[0].trim_space()
				if raw_window_name.len == 0 {
					continue
				}

				// Use safer name processing instead of texttools.name_fix
				mut window_name := raw_window_name.to_lower().trim_space()
				// Replace problematic characters with underscores
				window_name = window_name.replace(' ', '_').replace('-', '_').replace('.',
					'_')

				// Remove any non-ASCII characters safely
				mut safe_name := ''
				for c in window_name {
					if c.is_letter() || c.is_digit() || c == `_` {
						safe_name += c.ascii_str()
					}
				}
				window_name = safe_name

				if window_name.len == 0 {
					continue
				}

				window_id := parts[1].replace('@', '').int()
				window_active := parts[2] == '1'

				// Safe map assignment
				current_windows[window_name] = true

				// Update existing window or create new one
				mut found := false
				for mut w in s.windows {
					if w.name.len > 0 && window_name.len > 0 && w.name == window_name {
						w.id = window_id
						w.active = window_active
						w.scan()! // Scan panes for this window
						found = true
						break
					}
				}

				if !found {
					mut new_window := Window{
						session: &s
						name:    window_name
						id:      window_id
						active:  window_active
						panes:   []&Pane{}
						env:     map[string]string{}
					}
					new_window.scan()! // Scan panes for new window
					s.windows << &new_window
				}
			}
		}
	}

	// Remove windows that no longer exist in tmux
	mut valid_windows := []&Window{}
	for window in s.windows {
		// Safety check: ensure window.name is valid
		if window.name.len > 0 {
			// Avoid map access entirely - check if window still exists by comparing with current windows
			mut window_exists := false
			for current_name, _ in current_windows {
				if window.name == current_name {
					window_exists = true
					break
				}
			}
			if window_exists {
				valid_windows << window
			}
		}
	}
	s.windows = valid_windows
}

// window_name is the name of the window in session main (will always be called session main)
// cmd to execute e.g. bash file
// environment arguments to use
// reset, if reset it will create window even if it does already exist, will destroy it
// ```
// struct WindowArgs {
// pub mut:
// 	name    string
// 	cmd		string
// 	env		map[string]string	
// 	reset	bool
// }
// ```
pub fn (mut s Session) window_new(args WindowArgs) !&Window {
	$if debug {
		console.print_header(' start window: \n${args}')
	}
	namel := texttools.name_fix(args.name)
	if s.window_exist(name: namel) {
		if args.reset {
			s.window_delete(name: namel)!
		} else {
			return error('cannot create new window it already exists, window ${namel} in session:${s.name}')
		}
	}
	mut w := &Window{
		session: &s
		name:    namel
		panes:   []&Pane{}
		env:     args.env
	}
	s.windows << &w

	// Create the window with the specified command
	w.create(args.cmd)!
	s.scan()!

	return w
}

// get all windows as found in a session
pub fn (mut s Session) windows_get() []&Window {
	mut res := []&Window{}
	// os.log('TMUX - Start listing  ....')
	for _, window in s.windows {
		res << window
	}
	return res
}

// List windows in a session
pub fn (mut s Session) window_list() []&Window {
	return s.windows
}

pub fn (mut s Session) window_names() []string {
	mut res := []string{}
	for _, window in s.windows {
		res << window.name
	}
	return res
}

pub fn (mut s Session) str() string {
	mut out := '## Session: ${s.name}\n\n'
	for _, w in s.windows {
		out += '${*w}\n'
	}
	return out
}

pub fn (mut s Session) stats() !ProcessStats {
	mut total := ProcessStats{}
	for mut window in s.windows {
		stats := window.stats() or { continue }
		total.cpu_percent += stats.cpu_percent
		total.memory_bytes += stats.memory_bytes
		total.memory_percent += stats.memory_percent
	}
	return total
}

// pub fn (mut s Session) activate()! {
// 	active_session := s.tmux.redis.get('tmux:active_session') or { 'No active session found' }
// 	if active_session != 'No active session found' && s.name != active_session {
// 		s.tmuxexecutor.db.exec('tmux attach-session -t $active_session') or {
// 			return error('Fail to attach to current active session: $active_session \n$err')
// 		}
// 		s.tmuxexecutor.db.exec('tmux switch -t $s.name') or {
// 			return error("Can't switch to session $s.name \n$err")
// 		}
// 		s.tmux.redis.set('tmux:active_session', s.name) or { panic('Failed to set tmux:active_session') }
// 		os.log('SESSION - Session: $s.name activated ')
// 	} else if active_session == 'No active session found' {
// 		s.tmux.redis.set('tmux:active_session', s.name) or { panic('Failed to set tmux:active_session') }
// 		os.log('SESSION - Session: $s.name activated ')
// 	} else {
// 		os.log('SESSION - Session: $s.name already activate ')
// 	}
// }

fn (mut s Session) window_exist(args_ WindowGetArgs) bool {
	mut args := args_
	s.window_get(args) or { return false }
	return true
}

pub fn (mut s Session) window_get(args_ WindowGetArgs) !&Window {
	mut args := args_
	if args.name.len == 0 {
		return error('Window name cannot be empty')
	}
	args.name = texttools.name_fix_token(args.name)
	for w in s.windows {
		if w.name.len > 0 && w.name == args.name {
			if (args.id > 0 && w.id == args.id) || args.id == 0 {
				return w
			}
		}
	}
	return error('Cannot find window ${args.name} in session:${s.name}')
}

pub fn (mut s Session) window_delete(args_ WindowGetArgs) ! {
	// $if debug { console.print_debug(" - window delete: $args_")}
	mut args := args_
	args.name = texttools.name_fix_token(args.name)
	if !(s.window_exist(args)) {
		return
	}
	mut i := 0
	for mut w in s.windows {
		if w.name == args.name {
			if (args.id > 0 && w.id == args.id) || args.id == 0 {
				w.stop()!
				break
			}
		}
		i += 1
	}
	s.windows.delete(i) // i is now the one in the list which needs to be removed	
}

pub fn (mut s Session) restart() ! {
	s.stop()!
	s.create()!
}

pub fn (mut s Session) stop() ! {
	osal.execute_silent('tmux kill-session -t ${s.name}') or {
		return error("Can't delete session ${s.name} - This may happen when session is not found: ${err}")
	}
}

// Run ttyd for this session so it can be accessed in the browser
pub fn (mut s Session) run_ttyd(args TtydArgs) ! {
	target := '${s.name}'

	// Add -W flag for write access if editable mode is enabled
	mut ttyd_flags := '-p ${args.port}'
	if args.editable {
		ttyd_flags += ' -W'
	}

	cmd := 'nohup ttyd ${ttyd_flags} tmux attach -t ${target} >/dev/null 2>&1 &'

	code := os.system(cmd)
	if code != 0 {
		return error('Failed to start ttyd on port ${args.port} for session ${s.name}')
	}

	mode_str := if args.editable { 'editable' } else { 'read-only' }
	println('ttyd started for session ${s.name} at http://localhost:${args.port} (${mode_str} mode)')
}

// Backward compatibility method - runs ttyd in read-only mode
pub fn (mut s Session) run_ttyd_readonly(port int) ! {
	s.run_ttyd(port: port, editable: false)!
}

// Stop ttyd for this session by killing the process on the specified port
pub fn (mut s Session) stop_ttyd(port int) ! {
	// Kill any process running on the specified port
	cmd := 'lsof -ti:${port} | xargs kill -9'
	osal.execute_silent(cmd) or { return error("Can't stop ttyd on port ${port}: ${err}") }
}

// Stop all ttyd processes (kills all ttyd processes system-wide)
pub fn stop_all_ttyd() ! {
	cmd := 'pkill ttyd'
	osal.execute_silent(cmd) or { return error("Can't stop all ttyd processes: ${err}") }
}
