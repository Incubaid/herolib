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

	// Imperative functions (action after action)
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

	// Declarative functions (desired state)
	play_session_ensure(mut plbook, mut tmux_instance)!
	play_window_ensure(mut plbook, mut tmux_instance)!
	play_pane_ensure(mut plbook, mut tmux_instance)!
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

// DECLARATIVE FUNCTIONS - Ensure desired state exists

// Ensure session exists (declarative)
fn play_session_ensure(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.session_ensure')!
	for mut action in actions {
		mut p := action.params
		session_name := p.get('name')!

		// Ensure session exists, create if it doesn't
		if !tmux_instance.session_exist(session_name) {
			tmux_instance.session_create(name: session_name)!
		}

		action.done = true
	}
}

// Pane layout configurations for different categories
struct PaneLayout {
	splits []PaneSplit
}

struct PaneSplit {
	horizontal  bool
	target_pane int // which pane to split (0-based index)
}

// Get pane layout configuration based on category
fn get_pane_layout(category string) PaneLayout {
	match category {
		'1pane' {
			return PaneLayout{
				splits: []
			}
		}
		'2pane' {
			return PaneLayout{
				splits: [
					PaneSplit{
						horizontal:  true
						target_pane: 0
					},
				]
			}
		}
		'4pane' {
			return PaneLayout{
				splits: [
					PaneSplit{
						horizontal:  true
						target_pane: 0
					}, // Split horizontally first
					PaneSplit{
						horizontal:  false
						target_pane: 0
					}, // Split left pane vertically
					PaneSplit{
						horizontal:  false
						target_pane: 1
					}, // Split right pane vertically
				]
			}
		}
		'6pane' {
			return PaneLayout{
				splits: [
					PaneSplit{
						horizontal:  true
						target_pane: 0
					}, // Split horizontally
					PaneSplit{
						horizontal:  true
						target_pane: 1
					}, // Split right pane horizontally
					PaneSplit{
						horizontal:  false
						target_pane: 0
					}, // Split left pane vertically
					PaneSplit{
						horizontal:  false
						target_pane: 1
					}, // Split middle pane vertically
					PaneSplit{
						horizontal:  false
						target_pane: 2
					}, // Split right pane vertically
				]
			}
		}
		'8pane' {
			return PaneLayout{
				splits: [
					PaneSplit{
						horizontal:  true
						target_pane: 0
					}, // Split horizontally
					PaneSplit{
						horizontal:  false
						target_pane: 0
					}, // Split left vertically
					PaneSplit{
						horizontal:  false
						target_pane: 1
					}, // Split right vertically
					PaneSplit{
						horizontal:  true
						target_pane: 0
					}, // Split top-left horizontally
					PaneSplit{
						horizontal:  true
						target_pane: 1
					}, // Split bottom-left horizontally
					PaneSplit{
						horizontal:  true
						target_pane: 2
					}, // Split top-right horizontally
					PaneSplit{
						horizontal:  true
						target_pane: 3
					}, // Split bottom-right horizontally
				]
			}
		}
		'12pane' {
			return PaneLayout{
				splits: [
					PaneSplit{
						horizontal:  true
						target_pane: 0
					}, // Split horizontally (2 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 1
					}, // Split right horizontally (3 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 0
					}, // Split left vertically (4 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 1
					}, // Split middle vertically (5 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 2
					}, // Split right vertically (6 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 0
					}, // Split top-left horizontally (7 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 1
					}, // Split bottom-left horizontally (8 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 2
					}, // Split top-middle horizontally (9 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 3
					}, // Split bottom-middle horizontally (10 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 4
					}, // Split top-right horizontally (11 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 5
					}, // Split bottom-right horizontally (12 panes)
				]
			}
		}
		'16pane' {
			return PaneLayout{
				splits: [
					PaneSplit{
						horizontal:  true
						target_pane: 0
					}, // Split horizontally (2 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 0
					}, // Split left vertically (3 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 1
					}, // Split right vertically (4 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 0
					}, // Split top-left horizontally (5 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 1
					}, // Split bottom-left horizontally (6 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 2
					}, // Split top-right horizontally (7 panes)
					PaneSplit{
						horizontal:  true
						target_pane: 3
					}, // Split bottom-right horizontally (8 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 0
					}, // Split first quarter vertically (9 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 1
					}, // Split second quarter vertically (10 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 2
					}, // Split third quarter vertically (11 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 3
					}, // Split fourth quarter vertically (12 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 4
					}, // Split fifth quarter vertically (13 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 5
					}, // Split sixth quarter vertically (14 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 6
					}, // Split seventh quarter vertically (15 panes)
					PaneSplit{
						horizontal:  false
						target_pane: 7
					}, // Split eighth quarter vertically (16 panes)
				]
			}
		}
		else {
			// Default to 1pane if unknown category
			return PaneLayout{
				splits: []
			}
		}
	}
}

// Ensure window exists with specified pane layout (declarative)
fn play_window_ensure(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.window_ensure')!
	for mut action in actions {
		mut p := action.params
		name := p.get('name')!
		parsed := parse_window_name(name)!
		category := p.get_default('cat', '1pane')!
		cmd := p.get_default('cmd', '')!

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

		// Ensure session exists
		mut session := if tmux_instance.session_exist(parsed.session) {
			tmux_instance.session_get(parsed.session)!
		} else {
			tmux_instance.session_create(name: parsed.session)!
		}

		// Check if window already exists with correct pane layout
		mut window_exists := session.window_exist(name: parsed.window)
		mut window := if window_exists {
			session.window_get(name: parsed.window)!
		} else {
			// Create new window
			session.window_new(
				name: parsed.window
				cmd:  cmd
				env:  env
			)!
		}

		// Ensure correct pane layout
		layout := get_pane_layout(category)
		current_pane_count := window.panes.len

		// If we need more panes, create them according to layout
		if layout.splits.len + 1 > current_pane_count {
			// We need to create the layout from scratch
			// First, ensure we have at least one pane (the window should have one by default)
			window.scan()! // Refresh pane information

			// Apply splits according to layout
			for split in layout.splits {
				// For simplicity, we'll split the active pane
				// In a more sophisticated implementation, we could track specific panes
				window.pane_split(
					cmd:        cmd
					horizontal: split.horizontal
					env:        env
				)!
			}

			// After creating all panes, resize them to equal dimensions dynamically
			window.resize_panes_equal()!
		}

		action.done = true
	}
}

// Ensure specific pane exists with command and label (declarative)
fn play_pane_ensure(mut plbook PlayBook, mut tmux_instance Tmux) ! {
	mut actions := plbook.find(filter: 'tmux.pane_ensure')!
	for mut action in actions {
		mut p := action.params
		name := p.get('name')!
		parsed := parse_pane_name(name)!
		cmd := p.get_default('cmd', '')!
		label := p.get_default('label', '')!

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

		// Ensure session exists
		mut session := if tmux_instance.session_exist(parsed.session) {
			tmux_instance.session_get(parsed.session)!
		} else {
			tmux_instance.session_create(name: parsed.session)!
		}

		// Ensure window exists
		mut window := if session.window_exist(name: parsed.window) {
			session.window_get(name: parsed.window)!
		} else {
			session.window_new(name: parsed.window)!
		}

		// Refresh pane information
		window.scan()!

		// Check if we need to create more panes or execute command in existing pane
		pane_number := parsed.pane.int()

		// Ensure we have enough panes (create splits if needed)
		for window.panes.len < pane_number {
			window.pane_split(
				cmd:        '/bin/bash'
				horizontal: window.panes.len % 2 == 0 // Alternate between horizontal and vertical
				env:        env
			)!
		}

		// Execute command in the specified pane if provided
		if cmd.len > 0 {
			// Find the target pane (by index, since tmux pane IDs can vary)
			if pane_number > 0 && pane_number <= window.panes.len {
				mut target_pane := window.panes[pane_number - 1] // Convert to 0-based index
				target_pane.send_command(cmd)!
			}
		}

		action.done = true
	}
}
