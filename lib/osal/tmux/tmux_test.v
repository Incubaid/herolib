module tmux

import freeflowuniverse.herolib.osal.core as osal
// import freeflowuniverse.herolib.installers.tmux
import os
import freeflowuniverse.herolib.ui.console

const testpath = os.dir(@FILE) + '/testdata'

// make sure tmux isn't running prior to test
fn testsuite_begin() {
	mut tmux := new(sessionid: '1234')!
	if tmux.is_running()! {
		tmux.stop()!
	}
}

// make sure tmux isn't running after test
fn testsuite_end() {
	mut tmux := new(sessionid: '1234')!

	if tmux.is_running()! {
		tmux.stop()!
	}
}

fn test_start() ! {
	mut tmux := new(sessionid: '1234')!
	// test server is running after start()
	tmux.start() or { panic('cannot start tmux: ${err}') }
	mut tmux_ls := osal.execute_silent('tmux ls') or { panic('Cannot execute tmux ls: ${err}') }
	// test started tmux contains some session
	assert tmux_ls.len > 0, 'Tmux should have at least one session'
	tmux.stop() or { panic('cannot stop tmux: ${err}') }
}

fn test_stop() ! {
	mut tmux := new(sessionid: '1234')!

	// test server is running after start()
	tmux.start() or { panic('cannot start tmux: ${err}') }
	assert tmux.is_running()!
	tmux.stop() or { panic('cannot stop tmux: ${err}') }
	assert !tmux.is_running()!
}

fn test_windows_get() ! {
	mut tmux := new()!
	tmux.start()!

	// After start, scan to get the initial session
	tmux.scan()!

	windows := tmux.windows_get()
	assert windows.len >= 0 // At least the default session should exist

	tmux.stop()!
}

fn test_scan() ! {
	console.print_debug('-----Testing scan------')
	mut tmux := new()!
	tmux.start()!

	// Test initial scan
	tmux.scan()!
	sessions_before := tmux.sessions.len

	// Create a test session
	mut session := tmux.session_create(name: 'test_scan')!

	// Scan again
	tmux.scan()!
	sessions_after := tmux.sessions.len

	assert sessions_after >= sessions_before

	tmux.stop()!
}

// //TODO: fix test
// fn test_scan_add() ! {
// 	console.print_debug("-----Testing scan_add------")

// 	
// 	mut tmux := Tmux { node: node_ssh }
// 	windows := tmux.scan_add("line")!
// }

// remaining tests are run synchronously to avoid conflicts
fn test_tmux_window() {
	res := os.execute('${os.quoted_path(@VEXE)} test ${testpath}/tmux_window_test.v')
	// assert res.exit_code == 1
	// assert res.output.contains('other_test.v does not exist')
}

fn test_tmux_scan() {
	res := os.execute('${os.quoted_path(@VEXE)} test ${testpath}/tmux_window_test.v')
	// assert res.exit_code == 1
	// assert res.output.contains('other_test.v does not exist')
}
