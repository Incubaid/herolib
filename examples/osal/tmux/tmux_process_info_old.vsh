#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.osal.tmux
import freeflowuniverse.herolib.osal.core as osal
import time

mut t := tmux.new()!
if !t.is_running()! {
	t.start()!
}

// Create a session and window
mut session := t.session_create(name: 'test')!
mut window := session.window_new(name: 'monitoring', cmd: 'top', reset: true)!

// Wait a moment for the process to start
time.sleep(1000 * time.millisecond)

// Get the active pane
if mut pane := window.pane_active() {
	// Get process info for the pane and its children
	process_map := pane.processinfo()!

	println('Process tree for pane ${pane.id}:')
	for process in process_map.processes {
		println('  PID: ${process.pid}, CPU: ${process.cpu_perc}%, Memory: ${process.mem_perc}%, Command: ${process.cmd}')
	}

	// Get just the main process info
	main_process := pane.processinfo_main()!
	println('\nMain process: PID ${main_process.pid}, Command: ${main_process.cmd}')
}
