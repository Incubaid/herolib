#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.osal.tmux
import time

println('=== Tmux Pane Resizing Example ===')

mut t := tmux.new()!

if !t.is_running()! {
	println('Starting tmux server...')
	t.start()!
}

if t.session_exist('resize_demo') {
	println('Deleting existing resize_demo session...')
	t.session_delete('resize_demo')!
}

// Create session and window
println('Creating resize_demo session...')
mut session := t.session_create(name: 'resize_demo')!

println('Creating main window...')
mut window := session.window_new(name: 'main', cmd: 'bash', reset: true)!

time.sleep(500 * time.millisecond)
t.scan()!

// Create a 2x2 grid of panes
println('\n=== Creating 2x2 Grid of Panes ===')

// Split horizontally first (left | right)
mut right_pane := window.pane_split_horizontal('htop')!
time.sleep(300 * time.millisecond)

// Split left pane vertically (top-left, bottom-left)
window.scan()!
if window.panes.len > 1 {
	mut left_pane := window.panes[1] // The original bash pane
	left_pane.select()!
	time.sleep(200 * time.millisecond)
}
mut bottom_left_pane := window.pane_split_vertical('top')!
time.sleep(300 * time.millisecond)

// Split right pane vertically (top-right, bottom-right)
window.scan()!
for mut pane in window.panes {
	if pane.cmd.contains('htop') {
		pane.select()!
		break
	}
}
time.sleep(200 * time.millisecond)
mut bottom_right_pane := window.pane_split_vertical('tail -f /var/log/system.log')!
time.sleep(500 * time.millisecond)

window.scan()!
println('Created 2x2 grid with ${window.panes.len} panes:')
for i, pane in window.panes {
	println('  Pane ${i}: ID=%${pane.id}, Cmd="${pane.cmd}"')
}

// Demonstrate resizing operations
println('\n=== Demonstrating Pane Resizing ===')

// Get references to panes for resizing
window.scan()!
if window.panes.len >= 4 {
	mut top_left := window.panes[1] // bash
	mut top_right := window.panes[0] // htop
	mut bottom_left := window.panes[2] // top
	mut bottom_right := window.panes[3] // tail

	println('Resizing top-left pane (bash) to be wider...')
	top_left.select()!
	time.sleep(200 * time.millisecond)
	top_left.resize_right(10)!
	time.sleep(1000 * time.millisecond)

	println('Resizing top-right pane (htop) to be taller...')
	top_right.select()!
	time.sleep(200 * time.millisecond)
	top_right.resize_down(5)!
	time.sleep(1000 * time.millisecond)

	println('Resizing bottom-left pane (top) to be narrower...')
	bottom_left.select()!
	time.sleep(200 * time.millisecond)
	bottom_left.resize_left(5)!
	time.sleep(1000 * time.millisecond)

	println('Resizing bottom-right pane (tail) to be shorter...')
	bottom_right.select()!
	time.sleep(200 * time.millisecond)
	bottom_right.resize_up(3)!
	time.sleep(1000 * time.millisecond)

	// Demonstrate using the generic resize method
	println('Using generic resize method to make top-left pane taller...')
	top_left.select()!
	time.sleep(200 * time.millisecond)
	top_left.resize(direction: 'down', cells: 3)!
	time.sleep(1000 * time.millisecond)
}

// Send some commands to make the panes more interesting
println('\n=== Adding Content to Panes ===')
window.scan()!
if window.panes.len >= 4 {
	// Send commands to bash pane
	mut bash_pane := window.panes[1]
	bash_pane.send_command('echo "=== Bash Pane ==="')!
	bash_pane.send_command('ls -la')!
	bash_pane.send_command('pwd')!
	time.sleep(500 * time.millisecond)

	// Send command to top pane
	mut top_pane := window.panes[2]
	top_pane.send_command('echo "=== Top Pane ==="')!
	time.sleep(500 * time.millisecond)
}

println('\n=== Final Layout ===')
t.scan()!
println('Session: ${session.name}')
println('Window: ${window.name} (${window.panes.len} panes)')
for i, pane in window.panes {
	println('  ${i + 1}. Pane %${pane.id} - ${pane.cmd}')
}

println('\n=== Pane Resize Operations Available ===')
println('✓ resize_up(cells) - Make pane taller by shrinking pane above')
println('✓ resize_down(cells) - Make pane taller by shrinking pane below')
println('✓ resize_left(cells) - Make pane wider by shrinking pane to the left')
println('✓ resize_right(cells) - Make pane wider by shrinking pane to the right')
println('✓ resize(direction: "up/down/left/right", cells: N) - Generic resize method')

println('\nExample completed! You can attach to the session with:')
println('  tmux attach-session -t resize_demo')
println('\nThen use Ctrl+B followed by arrow keys to manually resize panes,')
println('or Ctrl+B followed by Alt+arrow keys for larger resize steps.')
