#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.osal.sshagent
import freeflowuniverse.herolib.osal.linux
import freeflowuniverse.herolib.ui.console

fn demo_sshagent_basic() ! {
	console.print_header('SSH Agent Basic Demo')

	// Create SSH agent
	mut agent := sshagent.new()!
	console.print_debug('SSH Agent initialized')

	// Show current status
	console.print_header('Current SSH Agent Status:')
	println(agent)

	// Show diagnostics
	diag := agent.diagnostics()
	console.print_header('SSH Agent Diagnostics:')
	for key, value in diag {
		console.print_item('${key}: ${value}')
	}
}

fn demo_sshagent_key_management() ! {
	console.print_header('SSH Agent Key Management Demo')

	mut agent := sshagent.new()!

	// Generate a test key if it doesn't exist
	test_key_name := 'herolib_demo_key'

	// Clean up any existing test key first
	if existing_key := agent.get(name: test_key_name) {
		console.print_debug('Removing existing test key...')
		// Remove existing key files
		mut key_file := agent.homepath.file_get_new('${test_key_name}')!
		mut pub_key_file := agent.homepath.file_get_new('${test_key_name}.pub')!
		key_file.delete() or {}
		pub_key_file.delete() or {}
	} else {
		console.print_debug('No existing test key found')
	}

	// Generate new key with empty passphrase
	console.print_debug('Generating new SSH key: ${test_key_name}')
	mut new_key := agent.generate(test_key_name, '')!
	console.print_green('✓ Generated new SSH key: ${test_key_name}')

	// Show key information
	console.print_item('Key name: ${new_key.name}')
	console.print_item('Key type: ${new_key.cat}')
	console.print_item('Key loaded: ${new_key.loaded}')

	// Demonstrate key operations without loading (to avoid passphrase issues)
	console.print_header('Key file operations:')
	mut key_path := new_key.keypath()!
	mut pub_key_path := new_key.keypath_pub()!
	console.print_item('Private key path: ${key_path.path}')
	console.print_item('Public key path: ${pub_key_path.path}')

	// Show public key content
	pub_key_content := new_key.keypub()!
	preview_len := if pub_key_content.len > 60 { 60 } else { pub_key_content.len }
	console.print_item('Public key: ${pub_key_content[0..preview_len]}...')

	// Show agent status
	console.print_header('Agent status after key generation:')
	println(agent)

	// Clean up test key
	console.print_debug('Cleaning up test key...')
	key_path.delete()!
	pub_key_path.delete()!
	console.print_green('✓ Test key cleaned up')
}

fn demo_sshagent_with_existing_keys() ! {
	console.print_header('SSH Agent with Existing Keys Demo')

	mut agent := sshagent.new()!

	if agent.keys.len == 0 {
		console.print_debug('No SSH keys found. Generating example key...')
		mut key := agent.generate('example_demo_key', '')!
		key.load()!
		console.print_green('✓ Created and loaded example key')
	}

	console.print_header('Available SSH keys:')
	for key in agent.keys {
		status := if key.loaded { 'LOADED' } else { 'NOT LOADED' }
		console.print_item('${key.name} - ${status} (${key.cat})')
	}

	// Try to work with the first available key
	if agent.keys.len > 0 {
		mut first_key := agent.keys[0]
		console.print_header('Working with key: ${first_key.name}')

		if first_key.loaded {
			console.print_debug('Key is loaded, showing public key info...')
			pubkey := first_key.keypub() or { 'Could not read public key' }
			preview_len := if pubkey.len > 50 { 50 } else { pubkey.len }
			console.print_item('Public key preview: ${pubkey[0..preview_len]}...')
		}
	}
}

fn test_user_mgmt() ! {
	console.print_header('User Management Test')

	// Note: This requires root privileges and should be run carefully
	console.print_debug('User management test requires root privileges')
	console.print_debug('Skipping user management test in this demo')

	// Uncomment below to test user management (requires root)
	/*
	mut lf := linux.new()!
	// Test user creation
	lf.user_create(
		name:   'testuser'
		sshkey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3/2K7R8A/l0kM0/d'
	)!

	// Test ssh key creation
	lf.sshkey_create(
		username:    'testuser'
		sshkey_name: 'testkey'
	)!

	// Test ssh key deletion
	lf.sshkey_delete(
		username:    'testuser'
		sshkey_name: 'testkey'
	)!

	// Test user deletion
	lf.user_delete(name: 'testuser')!
	*/
}

fn main() {
	console.print_header('🔑 SSH Agent Example - HeroLib')

	demo_sshagent_basic() or {
		console.print_stderr('❌ Basic demo failed: ${err}')
		return
	}

	demo_sshagent_key_management() or {
		console.print_stderr('❌ Key management demo failed: ${err}')
		return
	}

	demo_sshagent_with_existing_keys() or {
		console.print_stderr('❌ Existing keys demo failed: ${err}')
		return
	}

	test_user_mgmt() or {
		console.print_stderr('❌ User management test failed: ${err}')
		return
	}

	console.print_header('🎉 All SSH Agent demos completed successfully!')
}
