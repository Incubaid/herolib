#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.herorun
import os

fn main() {
	// Get command from command line args
	if os.args.len < 2 {
		println('Usage: ./execute.vsh "command" [context_id]')
		exit(1)
	}

	cmd := os.args[1]
	// context_id := if os.args.len > 2 { os.args[2] } else { 'default' }

	// Create user with SSH key using sshagent module
	mut user := herorun.new_user(keyname: 'id_ed25519')!

	// Create executor using proper modules
	mut executor := herorun.new_executor(
		node_ip:      '65.21.132.119'
		user:         'root'
		container_id: 'ai_agent_container'
		keyname:      'id_ed25519'
	)!

	// Execute command using osal module for clean output
	output := executor.execute(cmd)!

	// Output only the command result
	print(output)
}
