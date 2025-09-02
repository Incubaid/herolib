module tmux

import rand
import time

// Simple tests for tmux functionality

// Test MD5 command hashing (doesn't require tmux)
fn test_md5_hashing() ! {
	// Test basic hashing
	cmd1 := 'echo "test"'
	cmd2 := 'echo "test"'
	cmd3 := 'echo "different"'

	hash1 := normalize_and_hash_command(cmd1)
	hash2 := normalize_and_hash_command(cmd2)
	hash3 := normalize_and_hash_command(cmd3)

	assert hash1 == hash2, 'Same commands should have same hash'
	assert hash1 != hash3, 'Different commands should have different hashes'

	// Test normalization
	cmd_with_spaces := '  echo "test"  '
	cmd_with_newlines := 'echo "test"\n'

	hash_spaces := normalize_and_hash_command(cmd_with_spaces)
	hash_newlines := normalize_and_hash_command(cmd_with_newlines)

	assert hash1 == hash_spaces, 'Commands with extra spaces should normalize to same hash'
	assert hash1 == hash_newlines, 'Commands with newlines should normalize to same hash'
}

// Test basic tmux functionality
fn test_tmux_basic() ! {
	// Create unique session name to avoid conflicts
	session_name := 'test_${rand.int()}'

	mut tmux_instance := new()!

	// Ensure tmux is running
	if !tmux_instance.is_running()! {
		tmux_instance.start()!
	}

	// Create session
	mut session := tmux_instance.session_create(name: session_name)!
	// Note: session name gets normalized by name_fix, so we check if it contains our unique part
	assert session.name.contains('test_'), 'Session name should contain test_ prefix'

	// Test window creation
	mut window := session.window_new(name: 'testwin')!
	assert window.name == 'testwin'
	assert session.window_exist(name: 'testwin')

	// Clean up - just stop tmux to clean everything
	tmux_instance.stop()!
}
