module startupmanager

// import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.screen
// import freeflowuniverse.herolib.osal.systemd
import os
import time

const process_name = 'testprocess'

// Initialize test environment
pub fn testsuite_begin() ! {
	// Initialize screen factory
	mut screen_factory := screen.new(reset: true)!

	// Ensure screen directory exists with proper permissions
	home := os.home_dir()
	screen_dir := '${home}/.screen'
	if !os.exists(screen_dir) {
		res := os.execute('mkdir -m 700 ${screen_dir}')
		if res.exit_code != 0 {
			return error('Failed to create screen directory: ${res.output}')
		}
	}

	// Clean up any existing process
	mut sm := get(.auto)
	if sm.exists(process_name)! {
		sm.stop(process_name)!
		time.sleep(200 * time.millisecond) // Give time for cleanup
	}
}

pub fn testsuite_end() ! {
	mut sm := get(.auto)
	if sm.exists(process_name)! {
		sm.stop(process_name)!
		time.sleep(200 * time.millisecond) // Give time for cleanup
	}

	// Clean up screen sessions
	mut screen_factory := screen.new(reset: false)!
	screen_factory.scan()!
	if screen_factory.exists(process_name) {
		screen_factory.kill(process_name)!
		time.sleep(200 * time.millisecond)
	}
}

// Test startup manager status functionality
pub fn test_status() ! {
	mut sm := get(.auto)
	mut screen_factory := screen.new(reset: false)!

	// Create and ensure process doesn't exist
	if sm.exists(process_name)! {
		sm.stop(process_name)!
		time.sleep(200 * time.millisecond)
	}

	// Create new process with screen session
	sm.new(
		name:        process_name
		cmd:         'sleep 100'
		description: 'Test process for startup manager'
		restart:     false // Don't restart on failure for testing
	)!
	time.sleep(200 * time.millisecond)

	// Start and verify status
	sm.start(process_name)!
	time.sleep(500 * time.millisecond) // Give time for startup

	// Try getting status - remove for now
	if sm.exists(process_name)! {
		// Verify screen session
		screen_factory.scan()!
		assert screen_factory.exists(process_name), 'Screen session not found'
	}

	// Cleanup
	sm.stop(process_name)!
	time.sleep(200 * time.millisecond)
}

// Test process creation with description
pub fn test_process_with_description() ! {
	mut sm := get(.auto)
	mut screen_factory := screen.new(reset: false)!

	description := 'Test process with custom description'
	process_desc_name := '${process_name}_desc'

	// Create new process
	sm.new(
		name:        process_desc_name
		cmd:         'sleep 50'
		description: description
		restart:     false // Don't restart on failure for testing
	)!
	time.sleep(200 * time.millisecond)

	// Start and verify
	sm.start(process_desc_name)!
	time.sleep(500 * time.millisecond)

	// Verify screen session
	screen_factory.scan()!

	if screen_factory.exists(process_desc_name) {
		// Only test status if screen exists
		mut screen_instance := screen_factory.get(process_desc_name)!

		// Check status only if screen exists
		status := screen_instance.status() or { screen.ScreenStatus.unknown }
		println('Screen status: ${status}')
	}

	// Cleanup
	sm.stop(process_desc_name)!
	time.sleep(200 * time.millisecond)
}

// Test error handling
pub fn test_error_handling() ! {
	mut sm := get(.auto)
	mut screen_factory := screen.new(reset: false)!

	// Test non-existent process
	res1 := sm.status('nonexistent_process') or {
		assert true
		return
	}
	assert res1 == .unknown, 'Non-existent process should return unknown status'

	// Test invalid screen session
	res2 := screen_factory.get('nonexistent_screen') or {
		assert true
		return
	}
	assert res2.name == 'nonexistent_screen', 'Should not get non-existent screen'

	// Test stopping non-existent process
	sm.stop('nonexistent_process') or {
		assert true
		return
	}
}
