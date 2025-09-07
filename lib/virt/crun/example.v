module crun

import freeflowuniverse.herolib.core.pathlib

pub fn example_factory() ! {
	// Create a new container configuration
	mut config := new(name: 'mycontainer')!
	
	// Configure the container
	config.set_command(['/bin/bash', '-c', 'echo "Hello from container"'])
		.set_working_dir('/app')
		.set_user(1000, 1000, [1001, 1002])
		.add_env('MY_VAR', 'my_value')
		.add_env('ANOTHER_VAR', 'another_value')
		.set_rootfs('/path/to/rootfs', false)
		.set_hostname('my-container')
		.set_memory_limit(1024 * 1024 * 1024) // 1GB
		.set_cpu_limits(100000, 50000, 1024)  // period, quota, shares
		.add_mount('/host/path', '/container/path', .bind, [.rw])
		.add_capability(.cap_sys_admin)
		.remove_capability(.cap_net_raw)
	
	// Generate and print JSON
	json_output := config.to_json()!
	println(json_output)
	
	// Save to file
	config.save_to_file('/tmp/config.json')!
	println('Configuration saved to /tmp/config.json')
}

pub fn example_simple() ! {
	// Simple container for running a shell
	mut config := new(name: 'shell')!
	
	config.set_command(['/bin/sh'])
		.set_rootfs('/path/to/alpine/rootfs', false)
		.set_hostname('alpine-shell')
	
	// Get the JSON
	json_str := config.to_json()!
	println('Simple container config:')
	println(json_str)
}