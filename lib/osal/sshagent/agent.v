module sshagent

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.builder

// Check if SSH agent is properly configured and all is good
pub fn agent_check(mut agent SSHAgent) ! {
	console.print_header('SSH Agent Check')

	// Ensure single agent is running
	agent.ensure_single_agent()!

	// Get diagnostics
	diag := agent.diagnostics()

	for key, value in diag {
		console.print_item('${key}: ${value}')
	}

	// Verify agent is responsive
	if !agent.is_agent_responsive() {
		return error('SSH agent is not responsive')
	}

	// Load all existing keys from ~/.ssh that aren't loaded yet
	agent.init()!

	console.print_green('✓ SSH Agent is properly configured and running')

	// Show loaded keys
	loaded_keys := agent.keys_loaded()!
	console.print_item('Loaded keys: ${loaded_keys.len}')
	for key in loaded_keys {
		console.print_item('  - ${key.name} (${key.cat})')
	}
}

// Create a new SSH key
pub fn sshkey_create(mut agent SSHAgent, name string, passphrase string) ! {
	console.print_header('Creating SSH key: ${name}')

	// Check if key already exists
	if agent.exists(name: name) {
		console.print_debug('SSH key "${name}" already exists')
		return
	}

	// Generate new key
	mut key := agent.generate(name, passphrase)!
	console.print_green('✓ SSH key "${name}" created successfully')

	// Automatically load the key
	key.load()!
	console.print_green('✓ SSH key "${name}" loaded into agent')
}

// Delete an SSH key
pub fn sshkey_delete(mut agent SSHAgent, name string) ! {
	console.print_header('Deleting SSH key: ${name}')

	// Check if key exists
	mut key := agent.get(name: name) or {
		console.print_debug('SSH key "${name}" does not exist')
		return
	}

	// Get key paths before deletion
	mut key_path := key.keypath() or {
		console.print_debug('Private key path not available for "${name}"')
		key.keypath_pub() or { return } // Just to trigger the path lookup
	}
	mut key_pub_path := key.keypath_pub() or {
		console.print_debug('Public key path not available for "${name}"')
		return
	}

	// Remove from agent if loaded
	if key.loaded {
		key.forget()!
	}

	// Delete key files
	if key_path.exists() {
		key_path.delete()!
		console.print_debug('Deleted private key: ${key_path.path}')
	}
	if key_pub_path.exists() {
		key_pub_path.delete()!
		console.print_debug('Deleted public key: ${key_pub_path.path}')
	}

	// Reinitialize agent to update key list
	agent.init()!

	console.print_green('✓ SSH key "${name}" deleted successfully')
}

// Load SSH key into agent
pub fn sshkey_load(mut agent SSHAgent, name string) ! {
	console.print_header('Loading SSH key: ${name}')

	mut key := agent.get(name: name) or { return error('SSH key "${name}" not found') }

	if key.loaded {
		console.print_debug('SSH key "${name}" is already loaded')
		return
	}

	key.load()!
	console.print_green('✓ SSH key "${name}" loaded into agent')
}

// Check if SSH key is valid
pub fn sshkey_check(mut agent SSHAgent, name string) ! {
	console.print_header('Checking SSH key: ${name}')

	mut key := agent.get(name: name) or { return error('SSH key "${name}" not found') }

	// Check if key files exist
	mut key_path := key.keypath() or { return error('Private key file not found for "${name}"') }

	mut key_pub_path := key.keypath_pub() or {
		return error('Public key file not found for "${name}"')
	}

	if !key_path.exists() {
		return error('Private key file does not exist: ${key_path.path}')
	}

	if !key_pub_path.exists() {
		return error('Public key file does not exist: ${key_pub_path.path}')
	}

	// Verify key can be loaded (if not already loaded)
	if !key.loaded {
		// Test load without actually loading (since forget is disabled)
		key_content := key_path.read()!
		if !key_content.contains('PRIVATE KEY') {
			return error('Invalid private key format in "${name}"')
		}
	}

	console.print_item('Key type: ${key.cat}')
	console.print_item('Loaded: ${key.loaded}')
	console.print_item('Email: ${key.email}')
	console.print_item('Private key: ${key_path.path}')
	console.print_item('Public key: ${key_pub_path.path}')

	console.print_green('✓ SSH key "${name}" is valid')
}
