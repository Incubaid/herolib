#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.osal.tmux
import time

println('=== Tmux Pane Splitting Example ===')

mut t := tmux.new()!

if !t.is_running()! {
	println('Starting tmux server...')
	t.start()!
}

if t.session_exist('panes_demo') {
	println('Deleting existing panes_demo session...')
	t.session_delete('panes_demo')!
}

// Create session and initial window
println('Creating panes_demo session...')
mut session := t.session_create(name: 'panes_demo')!

println('Creating main window...')
mut window := session.window_new(name: 'main', cmd: 'bash', reset: true)!

// Wait for initial setup
time.sleep(500 * time.millisecond)
t.scan()!

println('\n=== Initial State ===')
println('Window: ${window.name} (ID: ${window.id})')
println('Number of panes: ${window.panes.len}')

// Split the window horizontally (side by side)
println('\n=== Splitting Horizontally (Side by Side) ===')
mut right_pane := window.pane_split_horizontal('htop')!
time.sleep(500 * time.millisecond)
window.scan()!

println('After horizontal split:')
println('Number of panes: ${window.panes.len}')
for i, mut pane in window.panes {
	println('  Pane ${i}: ID=%${pane.id}, PID=${pane.pid}, Active=${pane.active}, Cmd="${pane.cmd}"')
}

// Split the right pane vertically (top and bottom)
println('\n=== Splitting Right Pane Vertically (Top and Bottom) ===')
// Get a fresh reference to the right pane after the first split
window.scan()!
if window.panes.len > 0 {
	// Find the pane with htop command (the one we just created)
	mut right_pane_fresh := &window.panes[0]
	for mut pane in window.panes {
		if pane.cmd.contains('htop') {
			right_pane_fresh = pane
			break
		}
	}

	// Select the right pane to make it active
	right_pane_fresh.select()!
	time.sleep(200 * time.millisecond)
}

mut bottom_pane := window.pane_split_vertical('top')!
time.sleep(500 * time.millisecond)
window.scan()!

println('After vertical split of right pane:')
println('Number of panes: ${window.panes.len}')
for i, mut pane in window.panes {
	println('  Pane ${i}: ID=%${pane.id}, PID=${pane.pid}, Active=${pane.active}, Cmd="${pane.cmd}"')
}

// Send commands to different panes
println('\n=== Sending Commands to Panes ===')

// Get the first pane (left side) and send some commands
if window.panes.len > 0 {
	mut left_pane := window.panes[0]
	println('Sending commands to left pane (ID: %${left_pane.id})')

	left_pane.send_command('echo "Hello from left pane!"')!
	time.sleep(200 * time.millisecond)

	left_pane.send_command('ls -la')!
	time.sleep(200 * time.millisecond)

	left_pane.send_command('pwd')!
	time.sleep(200 * time.millisecond)
}

// Send command to bottom pane
if window.panes.len > 2 {
	mut bottom_pane_ref := window.panes[2]
	println('Sending command to bottom pane (ID: %${bottom_pane_ref.id})')
	bottom_pane_ref.send_command('echo "Hello from bottom pane!"')!
	time.sleep(200 * time.millisecond)
}

// Capture output from panes
println('\n=== Capturing Pane Output ===')
for i, mut pane in window.panes {
	println('Output from Pane ${i} (ID: %${pane.id}):')
	logs := pane.logs_all() or {
		println('  Could not get logs: ${err}')
		continue
	}

	if logs.len > 0 {
		lines := logs.split_into_lines()
		// Show last 3 lines
		start_idx := if lines.len > 3 { lines.len - 3 } else { 0 }
		for j in start_idx .. lines.len {
			if lines[j].trim_space().len > 0 {
				println('  ${lines[j]}')
			}
		}
	}
	println('')
}

// Demonstrate pane selection
println('\n=== Demonstrating Pane Selection ===')
for i, mut pane in window.panes {
	println('Selecting pane ${i} (ID: %${pane.id})')
	pane.select()!
	time.sleep(300 * time.millisecond)
}

// Final state
println('\n=== Final Tmux State ===')
t.scan()!
println(t)

println('\n=== Pane Management Summary ===')
println('Created ${window.panes.len} panes in window "${window.name}":')
for i, pane in window.panes {
	println('  ${i + 1}. Pane %${pane.id} - PID: ${pane.pid} - Command: ${pane.cmd}')
}

// Demonstrate killing a pane
println('\n=== Demonstrating Pane Killing ===')
if window.panes.len > 2 {
	mut pane_to_kill := window.panes[2] // Kill the bottom pane
	println('Killing pane %${pane_to_kill.id} (${pane_to_kill.cmd})')
	pane_to_kill.kill()!
	time.sleep(500 * time.millisecond)
	window.scan()!

	println('After killing pane:')
	println('Number of panes: ${window.panes.len}')
	for i, pane in window.panes {
		println('  Pane ${i}: ID=%${pane.id}, PID=${pane.pid}, Cmd="${pane.cmd}"')
	}
}

println('\n=== Available Pane Operations ===')
println('✓ Split panes horizontally (side by side)')
println('✓ Split panes vertically (top and bottom)')
println('✓ Send commands to specific panes')
println('✓ Send raw keys to panes')
println('✓ Select/activate panes')
println('✓ Capture pane output')
println('✓ Get pane process information')
println('✓ Kill individual panes')

println('\nExample completed! You can attach to the session with:')
println('  tmux attach-session -t panes_demo')
