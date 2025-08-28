#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.osal.sshagent
import freeflowuniverse.herolib.builder
import freeflowuniverse.herolib.ui.console

console.print_header('SSH Agent Management Example')

// Create SSH agent with single instance guarantee
mut agent := sshagent.new_single()!
println('SSH Agent initialized and ensured single instance')

// Show diagnostics
diag := agent.diagnostics()
console.print_header('SSH Agent Diagnostics:')
for key, value in diag {
	console.print_item('${key}: ${value}')
}

// Show current agent status
println(agent)

// Example: Generate a test key if no keys exist
if agent.keys.len == 0 {
	console.print_header('No keys found, generating example key...')
	mut key := agent.generate('example_key', '')!
	console.print_debug('Generated key: ${key}')

	// Load the generated key
	key.load()!
	console.print_debug('Key loaded into agent')
}

// Example: Push key to remote node (uncomment and modify for actual use)
/*
console.print_header('Testing remote node key deployment...')
mut b := builder.new()!

// Create connection to remote node
mut node := b.node_new(
	ipaddr: 'root@192.168.1.100:22'  // Replace with actual remote host
	name: 'test_node'
)!

if agent.keys.len > 0 {
	key_name := agent.keys[0].name
	console.print_debug('Pushing key "${key_name}" to remote node...')
	
	// Push the key
	agent.push_key_to_node(mut node, key_name)!
	
	// Verify access
	if agent.verify_key_access(mut node, key_name)! {
		console.print_debug('✓ SSH key access verified')
	} else {
		console.print_debug('✗ SSH key access verification failed')
	}
	
	// Optional: Remove key from remote (for testing)
	// agent.remove_key_from_node(mut node, key_name)!
	// console.print_debug('Key removed from remote node')
}
*/

console.print_header('SSH Agent example completed successfully')
