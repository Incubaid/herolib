#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.osal.tmux
import freeflowuniverse.herolib.osal.core as osal
import time

// Constants for display formatting
const bytes_to_mb = 1024.0 * 1024.0
const cpu_precision = 1
const memory_precision = 3

println('=== Tmux Pane Example ===')

mut t := tmux.new()!

if !t.is_running()! {
	println('Starting tmux server...')
	t.start()!
}

if t.session_exist('demo') {
	println('Deleting existing demo session...')
	t.session_delete('demo')!
}

// Create session and window
println('Creating demo session...')
mut session := t.session_create(name: 'demo')!

println('Creating main window with htop...')
mut window := session.window_new(name: 'main', cmd: 'htop', reset: true)!

// Wait a moment for the window to be created
time.sleep(500 * time.millisecond)

// Refresh to get current state
t.scan()!

println('\n=== Current Tmux State ===')
println(t)

// Get the window and demonstrate pane functionality
mut main_window := session.window_get(name: 'main')!

println('\n=== Window Pane Information ===')
println('Window: ${main_window.name} (ID: ${main_window.id})')
println('Number of panes: ${main_window.panes.len}')

for i, mut pane in main_window.panes {
	println('Pane ${i}: ID=%${pane.id}, PID=${pane.pid}, Active=${pane.active}, Cmd="${pane.cmd}"')

	// Get pane stats
	stats := pane.stats() or {
		println('  Could not get stats: ${err}')
		continue
	}
	memory_mb := f64(stats.memory_bytes) / bytes_to_mb
	println('  CPU: ${stats.cpu_percent:.1f}%, Memory: ${stats.memory_percent:.3f}% (${memory_mb:.1f} MB)')
}

// Get the active pane
if mut active_pane := main_window.pane_active() {
	println('\n=== Active Pane Details ===')
	println('Active pane ID: %${active_pane.id}')
	println('Process ID: ${active_pane.pid}')
	println('Command: ${active_pane.cmd}')

	// Get process information
	process_info := active_pane.processinfo_main() or {
		println('Could not get process info: ${err}')
		osal.ProcessInfo{}
	}
	if process_info.pid > 0 {
		println('Process info: PID=${process_info.pid}, Command=${process_info.cmd}')
	}

	// Get recent logs
	println('\n=== Recent Pane Output ===')
	logs := active_pane.logs_all() or {
		println('Could not get logs: ${err}')
		''
	}
	if logs.len > 0 {
		lines := logs.split_into_lines()
		// Show last 5 lines
		start_idx := if lines.len > 5 { lines.len - 5 } else { 0 }
		for i in start_idx .. lines.len {
			if lines[i].trim_space().len > 0 {
				println('  ${lines[i]}')
			}
		}
	}
} else {
	println('No active pane found')
}

println('\n=== Creating Additional Windows ===')

// Create more windows to demonstrate multiple panes
mut monitor_window := session.window_new(name: 'monitor', cmd: 'top', reset: true)!
mut logs_window := session.window_new(name: 'logs', cmd: 'tail -f /var/log/system.log', reset: true)!

time.sleep(500 * time.millisecond)
t.scan()!

println('\n=== Final Tmux State ===')
println(t)

println('\n=== Window Statistics ===')
for mut win in session.windows {
	println('Window: ${win.name}')
	window_stats := win.stats() or {
		println('  Could not get window stats: ${err}')
		continue
	}
	memory_mb := f64(window_stats.memory_bytes) / bytes_to_mb
	println('  Total CPU: ${window_stats.cpu_percent:.1f}%')
	println('  Total Memory: ${window_stats.memory_percent:.3f}% (${memory_mb:.1f} MB)')
	println('  Panes: ${win.panes.len}')
}
