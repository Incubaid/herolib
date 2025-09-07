#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.herorun

// Create user with SSH key using sshagent module
mut user := herorun.new_user(keyname: 'id_ed25519')!

// Create executor with Alpine Python base image
mut executor := herorun.new_executor(
	node_ip:      '65.21.132.119'
	user:         'root'
	container_id: 'python_alpine_container'
	keyname:      'id_ed25519'
	image_script: 'examples/virt/herorun/images/python_server.sh'
	base_image:   .alpine_python // Use Alpine with Python pre-installed
)!

// Setup container
executor.setup()!

// Create container with Python Alpine base and Python server script
mut container := executor.get_or_create_container(
	name:         'python_alpine_container'
	image_script: 'examples/virt/herorun/images/python_server.sh'
	base_image:   .alpine_python
)!

println('✅ Setup complete with Python Alpine container')
println('Container: python_alpine_container')
println('Base image: Alpine Linux with Python 3 pre-installed')
println('Entry point: python_server.sh')

// Test the container to show Python is available
println('\n🐍 Testing Python availability...')
python_test := executor.execute('runc exec python_alpine_container python3 --version') or {
	println('❌ Python test failed: ${err}')
	return
}

println('✅ Python version: ${python_test}')

println('\n🚀 Running Python HTTP server...')
println('Note: This will start the server and exit (use runc run for persistent server)')

// Run the container to start the Python server
result := executor.execute('runc run python_alpine_container') or {
	println('❌ Container execution failed: ${err}')
	return
}

println('📋 Server output:')
println(result)

println('\n🎉 Python Alpine container executed successfully!')
println('💡 The Python HTTP server would run on port 8000 if started persistently')
