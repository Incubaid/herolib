module crun

pub fn example_heropods_compatible() ! {
	mut configs := map[string]&CrunConfig{}
	// Create a container configuration compatible with heropods template
	mut config := new(mut configs, name: 'heropods-example')!

	// Configure to match the template
	config.set_command(['/bin/sh'])
	config.set_working_dir('/')
	config.set_user(0, 0, [])
	config.add_env('PATH', '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin')
	config.add_env('TERM', 'xterm')
	config.set_rootfs('/tmp/rootfs', false) // This will be replaced by the actual path
	config.set_hostname('container')
	config.set_no_new_privileges(true)

	// Add the specific rlimit from template
	config.add_rlimit(.rlimit_nofile, 1024, 1024)

	// Validate the configuration
	config.validate()!

	// Generate and print JSON
	json_output := config.to_json()!
	println(json_output)

	// Save to file
	config.save_to_file('/tmp/heropods_config.json')!
	println('Heropods-compatible configuration saved to /tmp/heropods_config.json')
}

pub fn example_custom() ! {
	mut configs := map[string]&CrunConfig{}
	// Create a more complex container configuration
	mut config := new(mut configs, name: 'custom-container')!

	config.set_command(['/usr/bin/my-app', '--config', '/etc/myapp/config.yaml'])
	config.set_working_dir('/app')
	config.set_user(1000, 1000, [1001, 1002])
	config.add_env('MY_VAR', 'my_value')
	config.add_env('ANOTHER_VAR', 'another_value')
	config.set_rootfs('/path/to/rootfs', false)
	config.set_hostname('my-custom-container')
	config.set_memory_limit(1024 * 1024 * 1024) // 1GB
	config.set_cpu_limits(100000, 50000, 1024) // period, quota, shares
	config.set_pids_limit(500)
	config.add_mount('/host/path', '/container/path', .bind, [.rw])
	config.add_mount('/tmp/cache', '/app/cache', .tmpfs, [.rw, .noexec])
	config.add_capability(.cap_sys_admin)
	config.remove_capability(.cap_net_raw)
	config.add_rlimit(.rlimit_nproc, 100, 50)
	config.set_no_new_privileges(true)

	// Add some additional security hardening

	config.add_masked_path('/proc/kcore')
	config.add_readonly_path('/proc/sys')

	// Validate before use
	config.validate()!

	// Get the JSON
	json_str := config.to_json()!
	println('Custom container config:')
	println(json_str)
}
