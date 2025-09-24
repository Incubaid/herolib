#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.osal.sshagent
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

// Example: Working with existing keys
if agent.keys.len > 0 {
	console.print_header('Working with existing keys...')

	for i, key in agent.keys {
		console.print_debug('Key ${i + 1}: ${key.name}')
		console.print_debug('  Type: ${key.cat}')
		console.print_debug('  Loaded: ${key.loaded}')
		console.print_debug('  Email: ${key.email}')

		if !key.loaded {
			console.print_debug('  Loading key...')
			mut key_mut := key
			key_mut.load() or {
				console.print_debug('  Failed to load: ${err}')
				continue
			}
			console.print_debug('  ✓ Key loaded successfully')
		}
	}
}

// Example: Add a key from private key content
console.print_header('Example: Adding a key from content...')
console.print_debug('Note: This would normally use real private key content')
console.print_debug('For security, we skip this in the example')

// Example: Generate and manage a new key
console.print_header('Example: Generate a new test key...')
test_key_name := 'test_key_example'

// Check if test key already exists
existing_key := agent.get(name: test_key_name) or {
	console.print_debug('Test key does not exist, generating...')

	// Generate new key
	mut new_key := agent.generate(test_key_name, '')!
	console.print_debug('✓ Generated new key: ${new_key.name}')

	// Load it
	new_key.load()!
	console.print_debug('✓ Key loaded into agent')

	new_key
}

console.print_debug('Test key exists: ${existing_key.name}')

// Show final agent status
console.print_header('Final SSH Agent Status:')
println(agent)

console.print_header('SSH Agent example completed successfully')
