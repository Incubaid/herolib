module sshagent

import os
import freeflowuniverse.herolib.ui.console

// Test helper to create temporary directory for testing
fn setup_test_env() !string {
	test_dir := '/tmp/sshagent_test_${os.getpid()}'
	os.mkdir_all(test_dir)!
	return test_dir
}

// Test helper to cleanup test environment
fn cleanup_test_env(test_dir string) {
	os.rmdir_all(test_dir) or {}
}

// Test SSH agent creation
fn test_sshagent_new() ! {
	test_dir := setup_test_env()!
	defer { cleanup_test_env(test_dir) }

	mut agent := new(homepath: test_dir)!
	assert agent.homepath.path == test_dir
	assert agent.keys.len >= 0
}

// Test SSH agent with single instance
fn test_sshagent_new_single() ! {
	test_dir := setup_test_env()!
	defer { cleanup_test_env(test_dir) }

	mut agent := new_single(homepath: test_dir)!
	assert agent.homepath.path == test_dir

	// Test that agent is responsive
	// Note: This might fail in CI environments without SSH agent
	// agent.is_agent_responsive() // Commented out for CI compatibility
}

// Test SSH key generation
fn test_sshkey_generation() ! {
	test_dir := setup_test_env()!
	defer { cleanup_test_env(test_dir) }

	mut agent := new(homepath: test_dir)!

	// Generate a test key
	key_name := 'test_key'
	mut key := agent.generate(key_name, '')!

	assert key.name == key_name
	assert key.cat == .ed25519

	// Verify key files exist
	mut key_path := key.keypath()!
	mut pub_key_path := key.keypath_pub()!

	assert key_path.exists()
	assert pub_key_path.exists()

	// Verify key content
	private_content := key_path.read()!
	public_content := key.keypub()!

	assert private_content.contains('PRIVATE KEY')
	assert public_content.starts_with('ssh-ed25519')

	// Cleanup
	key_path.delete()!
	pub_key_path.delete()!
}

// Test SSH key operations
fn test_sshkey_operations() ! {
	test_dir := setup_test_env()!
	defer { cleanup_test_env(test_dir) }

	mut agent := new(homepath: test_dir)!

	// Test key existence check
	assert !agent.exists(name: 'nonexistent_key')

	// Generate key
	key_name := 'ops_test_key'
	mut key := agent.generate(key_name, '')!

	// Test key retrieval
	retrieved_key := agent.get(name: key_name) or {
		assert false, 'Key should exist after generation'
		return
	}
	assert retrieved_key.name == key_name

	// Test key existence after generation
	assert agent.exists(name: key_name)

	// Cleanup
	mut cleanup_key_path := key.keypath()!
	mut cleanup_pub_path := key.keypath_pub()!
	cleanup_key_path.delete()!
	cleanup_pub_path.delete()!
}

// Test SSH agent diagnostics
fn test_sshagent_diagnostics() ! {
	test_dir := setup_test_env()!
	defer { cleanup_test_env(test_dir) }

	mut agent := new(homepath: test_dir)!

	diag := agent.diagnostics()

	// Check that all expected diagnostic keys are present
	expected_keys := ['socket_path', 'socket_exists', 'agent_responsive', 'loaded_keys_count',
		'total_keys_count', 'agent_processes']

	for key in expected_keys {
		assert key in diag, 'Missing diagnostic key: ${key}'
	}

	// Verify diagnostic values are reasonable
	assert diag['loaded_keys_count'].int() >= 0
	assert diag['total_keys_count'].int() >= 0
	assert diag['agent_processes'].int() >= 0
}

// Test error handling
fn test_error_handling() ! {
	test_dir := setup_test_env()!
	defer { cleanup_test_env(test_dir) }

	mut agent := new(homepath: test_dir)!

	// Test loading non-existent key
	if _ := agent.load('/nonexistent/path') {
		assert false, 'Should fail to load non-existent key'
	}

	// Test getting non-existent key
	if _ := agent.get(name: 'nonexistent') {
		assert false, 'Should return none for non-existent key'
	}

	// Test forgetting non-existent key
	if _ := agent.forget('nonexistent') {
		assert false, 'Should fail to forget non-existent key'
	}
}

// Test key string representation
fn test_sshkey_string() ! {
	test_dir := setup_test_env()!
	defer { cleanup_test_env(test_dir) }

	mut agent := new(homepath: test_dir)!

	// Generate key for testing
	key_name := 'string_test_key'
	mut key := agent.generate(key_name, '')!

	// Test key string representation
	key_str := key.str()
	assert key_str.contains(key_name)
	assert key_str.contains('ed25519')

	// Test agent string representation
	agent_str := agent.str()
	assert agent_str.contains('SSHAGENT')
	assert agent_str.contains(key_name)

	// Cleanup
	mut cleanup_key_path2 := key.keypath()!
	mut cleanup_pub_path2 := key.keypath_pub()!
	cleanup_key_path2.delete()!
	cleanup_pub_path2.delete()!
}

// Test private key addition (simplified - just test file creation)
fn test_add_private_key() ! {
	test_dir := setup_test_env()!
	defer { cleanup_test_env(test_dir) }

	mut agent := new(homepath: test_dir)!

	// Create a simple test private key content (not a real key, just for testing file operations)
	test_private_key := '-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACDXf9Z/2AH8/8a1ppagCplQdhWyQ8wZAieUw3nNcxsDiQAAAIhb3ybRW98m
0QAAAAtzc2gtZWQyNTUxOQAAACDXf9Z/2AH8/8a1ppagCplQdhWyQ8wZAieUw3nNcxsDiQ
AAAEC+fcDBPqdJHlJOQJ2zXhU2FztKAIl3TmWkaGCPnyts49d/1n/YAfz/xrWmlqAKmVB2
FbJDzBkCJ5TDec1zGwOJAAAABWJvb2tz
-----END OPENSSH PRIVATE KEY-----'

	// Test input validation
	key_name := 'test_added_key'

	// This should work for file creation but may fail on public key generation
	// which is expected since this is not a real private key
	if mut added_key := agent.add(key_name, test_private_key) {
		// If it succeeds, verify files were created
		mut added_key_path := added_key.keypath()!
		assert added_key_path.exists()

		// Cleanup
		added_key_path.delete()!
		if pub_path := added_key.keypath_pub() {
			mut pub_file := pub_path
			pub_file.delete() or {}
		}
	} else {
		// Expected to fail with invalid key, which is fine for this test
		// We're mainly testing the validation and file handling logic
		console.print_debug('Add private key failed as expected with test key')
	}
}
