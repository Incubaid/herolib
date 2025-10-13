module tmux

import incubaid.herolib.osal.core as osal
import rand

fn testsuite_begin() {
	mut tmux_instance := new()!

	if tmux_instance.is_running()! {
		tmux_instance.stop()!
	}
}

fn test_session_create() ! {
	// Create unique session names to avoid conflicts
	session_name1 := 'testsession_${rand.int()}'
	session_name2 := 'testsession2_${rand.int()}'

	mut tmux_instance := new()!
	tmux_instance.start()!

	// Create sessions using the proper API
	mut s := tmux_instance.session_create(name: session_name1)!
	mut s2 := tmux_instance.session_create(name: session_name2)!

	// Test that sessions were created successfully
	mut tmux_ls := osal.execute_silent('tmux ls') or { panic("can't exec: ${err}") }
	assert tmux_ls.contains(session_name1), 'Session 1 should exist'
	assert tmux_ls.contains(session_name2), 'Session 2 should exist'

	// Test session existence check
	assert tmux_instance.session_exist(session_name1), 'Session 1 should exist via API'
	assert tmux_instance.session_exist(session_name2), 'Session 2 should exist via API'

	// Clean up
	tmux_instance.session_delete(session_name1)!
	tmux_instance.session_delete(session_name2)!
	tmux_instance.stop()!
}
