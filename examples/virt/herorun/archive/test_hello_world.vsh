#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.herorun

// Create user with SSH key using sshagent module
mut user := herorun.new_user(keyname: 'id_ed25519')!

// Create executor with hello world script
mut executor := herorun.new_executor(
	node_ip:      '65.21.132.119'
	user:         'root'
	container_id: 'hello_world_container'
	keyname:      'id_ed25519'
	image_script: 'examples/virt/herorun/images/hello_world.sh'
)!

// Setup container
executor.setup()!

// Create container with hello world script
mut container := executor.get_or_create_container(
	name:         'hello_world_container'
	image_script: 'examples/virt/herorun/images/hello_world.sh'
)!

println('✅ Setup complete with Hello World container')
println('Container: hello_world_container')
println('Entry point: hello_world.sh')

// Run the container to demonstrate it works
println('\n🚀 Running container...')
result := executor.execute('runc run hello_world_container') or {
	println('❌ Container execution failed: ${err}')
	return
}

println('📋 Container output:')
println(result)

println('\n🎉 Container executed successfully!')
