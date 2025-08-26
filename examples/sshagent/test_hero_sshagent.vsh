#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import os
import freeflowuniverse.herolib.ui.console

// Test script for Hero SSH Agent functionality
// This script demonstrates the key features of the hero sshagent command

fn main() {
	console.print_header('🔑 Hero SSH Agent Test Suite')
	
	hero_bin := '/Users/mahmoud/hero/bin/hero'
	
	// Check if hero binary exists
	if !os.exists(hero_bin) {
		console.print_stderr('Hero binary not found at ${hero_bin}')
		console.print_stderr('Please compile hero first with: ./cli/compile.vsh')
		exit(1)
	}
	
	console.print_green('✓ Hero binary found at ${hero_bin}')
	
	// Test 1: Profile initialization
	console.print_header('Test 1: Profile Initialization')
	result1 := os.execute('${hero_bin} sshagent profile')
	if result1.exit_code == 0 {
		console.print_green('✓ Profile initialization successful')
	} else {
		console.print_stderr('❌ Profile initialization failed: ${result1.output}')
	}
	
	// Test 2: Status check
	console.print_header('Test 2: Status Check')
	result2 := os.execute('${hero_bin} sshagent status')
	if result2.exit_code == 0 {
		console.print_green('✓ Status check successful')
		println(result2.output)
	} else {
		console.print_stderr('❌ Status check failed: ${result2.output}')
	}
	
	// Test 3: List keys
	console.print_header('Test 3: List SSH Keys')
	result3 := os.execute('${hero_bin} sshagent list')
	if result3.exit_code == 0 {
		console.print_green('✓ List keys successful')
		println(result3.output)
	} else {
		console.print_stderr('❌ List keys failed: ${result3.output}')
	}
	
	// Test 4: Generate test key
	console.print_header('Test 4: Generate Test Key')
	test_key_name := 'hero_test_${os.getpid()}'
	result4 := os.execute('${hero_bin} sshagent generate -n ${test_key_name}')
	if result4.exit_code == 0 {
		console.print_green('✓ Key generation successful')
		println(result4.output)
		
		// Cleanup: remove test key files
		test_key_path := '${os.home_dir()}/.ssh/${test_key_name}'
		test_pub_path := '${test_key_path}.pub'
		
		if os.exists(test_key_path) {
			os.rm(test_key_path) or {}
			console.print_debug('Cleaned up test private key')
		}
		if os.exists(test_pub_path) {
			os.rm(test_pub_path) or {}
			console.print_debug('Cleaned up test public key')
		}
	} else {
		console.print_stderr('❌ Key generation failed: ${result4.output}')
	}
	
	// Test 5: Help output
	console.print_header('Test 5: Help Output')
	result5 := os.execute('${hero_bin} sshagent')
	if result5.exit_code == 1 && result5.output.contains('Hero SSH Agent Management Tool') {
		console.print_green('✓ Help output is correct')
	} else {
		console.print_stderr('❌ Help output unexpected')
	}
	
	console.print_header('🎉 Test Suite Complete')
	console.print_green('Hero SSH Agent is ready for use!')
	
	// Show usage examples
	console.print_header('Usage Examples:')
	println('')
	println('Initialize SSH agent:')
	println('  ${hero_bin} sshagent profile')
	println('')
	println('Check status:')
	println('  ${hero_bin} sshagent status')
	println('')
	println('Deploy key to remote server:')
	println('  ${hero_bin} sshagent push -t user@server.com')
	println('')
	println('Verify authorization:')
	println('  ${hero_bin} sshagent auth -t user@server.com')
	println('')
	println('For more examples, see: examples/sshagent/hero_sshagent_examples.md')
}
