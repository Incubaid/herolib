#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.herorun

fn main() {
	// Create user with SSH key using sshagent module
	mut user := herorun.new_user(keyname: 'id_ed25519')!

	// Create executor using proper module integration
	mut executor := herorun.new_executor(
		node_ip:      '65.21.132.119'
		user:         'root'
		container_id: 'ai_agent_container'
		keyname:      'id_ed25519'
	)!

	// Setup using sshagent, tmux, hetznermanager, and osal modules
	executor.setup()!

	println('Setup complete')
}
