module tmux

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.osal.core as osal

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'tmux.') {
		return
	}

	// Create tmux instance
	mut tmux_instance := new()!

	// Start tmux if not running
	if !tmux_instance.is_running()! {
		tmux_instance.start()!
	}

	play_session_create(mut plbook, mut tmux_instance)!
	play_session_delete(mut plbook, mut tmux_instance)!
	play_window_create(mut plbook, mut tmux_instance)!
	play_window_delete(mut plbook, mut tmux_instance)!
	play_pane_execute(mut plbook, mut tmux_instance)!
	play_pane_kill(mut plbook, mut tmux_instance)!
	play_pane_split(mut plbook, mut tmux_instance)!
	play_session_ttyd(mut plbook, mut tmux_instance)!
	play_window_ttyd(mut plbook, mut tmux_instance)!
	play_session_ttyd_stop(mut plbook, mut tmux_instance)!
	play_window_ttyd_stop(mut plbook, mut tmux_instance)!
	play_ttyd_stop_all(mut plbook, mut tmux_instance)!
}

struct ParsedWindowName {
	session string
	window  string
}

struct ParsedPaneName {
	session string
	window  string
	pane    string
}

fn parse_window_name(name string) !ParsedWindowName {
	parts := name.split('|')
	if parts.len != 2 {
		return error('Window name must be in format "session|window", got: ${name}')
	}
	return ParsedWindowName{
		session: texttools.name_fix_token(parts[0])
		window:  texttools.name_fix_token(parts[1])
	}
}

fn parse_pane_name(name string) !ParsedPaneName {
	parts := name.split('|')
	if parts.len != 3 {
		return error('Pane name must be in format "session|window|pane", got: ${name}')
	}
	return ParsedPaneName{
		session: texttools.name_fix_token(parts[0])
		window:  texttools.name_fix_token(parts[1])
		pane:    texttools.name_fix_token(parts[2])
	}
}

fn play_session_create(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.session_create')!
	for mut action in actions {
		mut p := action.params
		session_name := p.get('name')!
		reset := p.get_default_false('reset')

		tmux_instance.session_create(
			name:  session_name
			reset: reset
		)!

		action.done = true
	}
}

fn play_session_delete(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.session_delete')!
	for mut action in actions {
		mut p := action.params
		session_name := p.get('name')!

		tmux_instance.session_delete(session_name)!

		action.done = true
	}
}

fn play_window_create(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.window_create')!
	for mut action in actions {
		mut p := action.params
		name := p.get('name')!
		parsed := parse_window_name(name)!
		cmd := p.get_default('cmd', '')!
		reset := p.get_default_false('reset')

		// Parse environment variables if provided
		mut env := map[string]string{}
		if env_str := p.get_default('env', '') {
			// Parse env as comma-separated key=value pairs
			env_pairs := env_str.split(',')
			for pair in env_pairs {
				kv := pair.split('=')
				if kv.len == 2 {
					env[kv[0].trim_space()] = kv[1].trim_space()
				}
			}
		}

		// Get or create session
		mut session := if tmux_instance.session_exist(parsed.session) {
			tmux_instance.session_get(parsed.session)!
		} else {
			tmux_instance.session_create(name: parsed.session)!
		}

		session.window_new(
			name:  parsed.window
			cmd:   cmd
			env:   env
			reset: reset
		)!

		action.done = true
	}
}

fn play_window_delete(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.window_delete')!
	for mut action in actions {
		mut p := action.params
		name := p.get('name')!
		parsed := parse_window_name(name)!

		if tmux_instance.session_exist(parsed.session) {
			mut session := tmux_instance.session_get(parsed.session)!
			session.window_delete(name: parsed.window)!
		}

		action.done = true
	}
}

fn play_pane_execute(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.pane_execute')!
	for mut action in actions {
		mut p := action.params
		name := p.get('name')!
		cmd := p.get('cmd')!
		parsed := parse_pane_name(name)!

		// Find the session and window
		if tmux_instance.session_exist(parsed.session) {
			mut session := tmux_instance.session_get(parsed.session)!
			if session.window_exist(name: parsed.window) {
				mut window := session.window_get(name: parsed.window)!

				// Send command to the window (goes to active pane by default)
				tmux_cmd := 'tmux send-keys -t ${session.name}:@${window.id} "${cmd}" Enter'
				osal.exec(cmd: tmux_cmd, stdout: false, name: 'tmux_pane_execute')!
			}
		}

		action.done = true
	}
}

fn play_pane_kill(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.pane_kill')!
	for mut action in actions {
		mut p := action.params
		name := p.get('name')!
		parsed := parse_pane_name(name)!

		// Find the session and window, then kill the active pane
		if tmux_instance.session_exist(parsed.session) {
			mut session := tmux_instance.session_get(parsed.session)!
			if session.window_exist(name: parsed.window) {
				mut window := session.window_get(name: parsed.window)!

				// Kill the active pane in the window
				if pane := window.pane_active() {
					tmux_cmd := 'tmux kill-pane -t ${session.name}:@${window.id}.%${pane.id}'
					osal.exec(
						cmd:          tmux_cmd
						stdout:       false
						name:         'tmux_pane_kill'
						ignore_error: true
					)!
				}
			}
		}

		action.done = true
	}
}

fn play_pane_split(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.pane_split')!
	for mut action in actions {
		mut p := action.params
		name := p.get('name')!
		cmd := p.get_default('cmd', '')!
		horizontal := p.get_default_false('horizontal')
		parsed := parse_window_name(name)!

		// Parse environment variables if provided
		mut env := map[string]string{}
		if env_str := p.get_default('env', '') {
			env_pairs := env_str.split(',')
			for pair in env_pairs {
				kv := pair.split('=')
				if kv.len == 2 {
					env[kv[0].trim_space()] = kv[1].trim_space()
				}
			}
		}

		// Find the session and window
		if tmux_instance.session_exist(parsed.session) {
			mut session := tmux_instance.session_get(parsed.session)!
			if session.window_exist(name: parsed.window) {
				mut window := session.window_get(name: parsed.window)!

				// Split the pane
				window.pane_split(
					cmd:        cmd
					horizontal: horizontal
					env:        env
				)!
			}
		}

		action.done = true
	}
}

fn play_session_ttyd(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.session_ttyd')!
	for mut action in actions {
		mut p := action.params
		session_name := p.get('name')!
		port := p.get_int('port')!
		editable := p.get_default_false('editable')

		if tmux_instance.session_exist(session_name) {
			mut session := tmux_instance.session_get(session_name)!
			session.run_ttyd(
				port:     port
				editable: editable
			)!
		}

		action.done = true
	}
}

fn play_window_ttyd(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.window_ttyd')!
	for mut action in actions {
		mut p := action.params
		name := p.get('name')!
		port := p.get_int('port')!
		editable := p.get_default_false('editable')
		parsed := parse_window_name(name)!

		if tmux_instance.session_exist(parsed.session) {
			mut session := tmux_instance.session_get(parsed.session)!
			if session.window_exist(name: parsed.window) {
				mut window := session.window_get(name: parsed.window)!
				window.run_ttyd(
					port:     port
					editable: editable
				)!
			}
		}

		action.done = true
	}
}

// Handle tmux.session_ttyd_stop actions
fn play_session_ttyd_stop(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	for mut action in plbook.find(filter: 'tmux.session_ttyd_stop')! {
		if action.done {
			continue
		}

		mut p := action.params
		session_name := p.get('name')!
		port := p.get_int('port')!

		mut session := tmux_instance.session_get(session_name)!
		session.stop_ttyd(port)!

		action.done = true
	}
}

// Handle tmux.window_ttyd_stop actions
fn play_window_ttyd_stop(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	for mut action in plbook.find(filter: 'tmux.window_ttyd_stop')! {
		if action.done {
			continue
		}

		mut p := action.params
		name := p.get('name')!
		port := p.get_int('port')!

		parsed := parse_window_name(name)!
		mut session := tmux_instance.session_get(parsed.session)!
		mut window := session.window_get(name: parsed.window)!
		window.stop_ttyd(port)!

		action.done = true
	}
}

// Handle tmux.ttyd_stop_all actions
fn play_ttyd_stop_all(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	for mut action in plbook.find(filter: 'tmux.ttyd_stop_all')! {
		if action.done {
			continue
		}

		stop_all_ttyd()!

		action.done = true
	}
}
