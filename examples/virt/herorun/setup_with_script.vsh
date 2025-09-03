#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.herorun

fn main() {
	// Create user with SSH key using sshagent module
	mut user := herorun.new_user(keyname: 'id_ed25519')!

	// Create executor with image script for Python server
	mut executor := herorun.new_executor(
		node_ip:      '65.21.132.119'
		user:         'root'
		container_id: 'python_server_container'
		keyname:      'id_ed25519'
		image_script: 'examples/virt/herorun/images/python_server.sh' // Path to entry point script
	)!

	// Setup using sshagent, tmux, hetznermanager, and osal modules
	executor.setup()!

	// Create container with the Python server script
	mut container := executor.get_or_create_container(
		name:         'python_server_container'
		image_script: 'examples/virt/herorun/images/python_server.sh'
	)!

	println('Setup complete with Python server container')
	println('Container: python_server_container')
	println('Entry point: examples/virt/herorun/images/python_server.sh (Python HTTP server)')
	println('To start the server: runc run python_server_container')
}
