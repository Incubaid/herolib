module heropods

import incubaid.herolib.core
import incubaid.herolib.osal.core as osal
import os

// Network-specific tests for HeroPods
//
// These tests verify bridge setup, IP allocation, NAT rules, and network cleanup

// Helper function to check if we're on Linux
fn is_linux_platform() bool {
	return core.is_linux() or { false }
}

// Helper function to skip test if not on Linux
fn skip_if_not_linux() {
	if !is_linux_platform() {
		eprintln('SKIP: Test requires Linux (crun, ip, iptables)')
		exit(0)
	}
}

// Setup minimal test rootfs for testing
fn setup_test_rootfs() ! {
	rootfs_path := os.home_dir() + '/.containers/images/alpine/rootfs'

	// Skip if already exists and has valid binaries
	if os.is_dir(rootfs_path) && os.is_file('${rootfs_path}/bin/sh') {
		// Check if sh is a real binary (> 1KB)
		sh_info := os.stat('${rootfs_path}/bin/sh') or { return }
		if sh_info.size > 1024 {
			return
		}
	}

	// Remove old rootfs if it exists
	if os.is_dir(rootfs_path) {
		os.rmdir_all(rootfs_path) or {}
	}

	// Create minimal rootfs structure
	os.mkdir_all(rootfs_path)!
	os.mkdir_all('${rootfs_path}/bin')!
	os.mkdir_all('${rootfs_path}/etc')!
	os.mkdir_all('${rootfs_path}/dev')!
	os.mkdir_all('${rootfs_path}/proc')!
	os.mkdir_all('${rootfs_path}/sys')!
	os.mkdir_all('${rootfs_path}/tmp')!
	os.mkdir_all('${rootfs_path}/usr/bin')!
	os.mkdir_all('${rootfs_path}/usr/local/bin')!
	os.mkdir_all('${rootfs_path}/lib/x86_64-linux-gnu')!
	os.mkdir_all('${rootfs_path}/lib64')!

	// Copy essential binaries from host
	// Use dash (smaller than bash) and sleep
	if os.exists('/bin/dash') {
		os.execute('cp -L /bin/dash ${rootfs_path}/bin/sh')
		os.chmod('${rootfs_path}/bin/sh', 0o755)!
	} else if os.exists('/bin/sh') {
		os.execute('cp -L /bin/sh ${rootfs_path}/bin/sh')
		os.chmod('${rootfs_path}/bin/sh', 0o755)!
	}

	// Copy common utilities
	for cmd in ['sleep', 'echo', 'cat', 'ls', 'pwd', 'true', 'false'] {
		if os.exists('/bin/${cmd}') {
			os.execute('cp -L /bin/${cmd} ${rootfs_path}/bin/${cmd}')
			os.chmod('${rootfs_path}/bin/${cmd}', 0o755) or {}
		} else if os.exists('/usr/bin/${cmd}') {
			os.execute('cp -L /usr/bin/${cmd} ${rootfs_path}/bin/${cmd}')
			os.chmod('${rootfs_path}/bin/${cmd}', 0o755) or {}
		}
	}

	// Copy required libraries for dash/sh
	// Copy from /lib/x86_64-linux-gnu to the same path in rootfs
	if os.is_dir('/lib/x86_64-linux-gnu') {
		os.execute('cp -a /lib/x86_64-linux-gnu/libc.so.6 ${rootfs_path}/lib/x86_64-linux-gnu/')
		os.execute('cp -a /lib/x86_64-linux-gnu/libc-*.so ${rootfs_path}/lib/x86_64-linux-gnu/ 2>/dev/null || true')
		// Copy dynamic linker (actual file, not symlink)
		os.execute('cp -L /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 ${rootfs_path}/lib/x86_64-linux-gnu/')
	}

	// Create symlink in /lib64 pointing to the actual file
	if os.is_dir('${rootfs_path}/lib64') {
		os.execute('ln -sf ../lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 ${rootfs_path}/lib64/ld-linux-x86-64.so.2')
	}

	// Create /etc/resolv.conf
	os.write_file('${rootfs_path}/etc/resolv.conf', 'nameserver 8.8.8.8\n')!
}

// Cleanup helper for tests
fn cleanup_test_heropods(name string) {
	mut hp := get(name: name) or { return }
	for container_name, mut container in hp.containers {
		container.stop() or {}
		container.delete() or {}
	}
	// Don't delete the bridge (false) - tests run in parallel and share the same bridge
	// Only clean up containers and IPs
	hp.network_cleanup_all(false) or {}
	delete(name: name) or {}
}

// Test 1: Bridge network setup
fn test_network_bridge_setup() ! {
	skip_if_not_linux()

	test_name := 'test_bridge_${os.getpid()}'

	mut hp := new(
		name:       test_name
		reset:      false // Don't reset to avoid race conditions with parallel tests
		use_podman: true  // Skip default image setup in tests
	)!

	bridge_name := hp.network_config.bridge_name

	// Verify bridge exists
	job := osal.exec(cmd: 'ip link show ${bridge_name}')!
	assert job.output.contains(bridge_name)

	// Verify bridge is UP
	assert job.output.contains('UP') || job.output.contains('state UP')

	// Verify IP is assigned to bridge
	job2 := osal.exec(cmd: 'ip addr show ${bridge_name}')!
	assert job2.output.contains(hp.network_config.gateway_ip)

	// Cleanup after test
	cleanup_test_heropods(test_name)

	println('✓ Bridge network setup test passed')
}

// Test 2: NAT rules verification
fn test_network_nat_rules() ! {
	skip_if_not_linux()

	test_name := 'test_nat_${os.getpid()}'
	defer { cleanup_test_heropods(test_name) }

	mut hp := new(
		name:       test_name
		reset:      false // Don't reset to avoid race conditions with parallel tests
		use_podman: true  // Skip default image setup in tests
	)!

	// Verify NAT rules exist for the subnet
	job := osal.exec(cmd: 'iptables -t nat -L POSTROUTING -n')!
	assert job.output.contains(hp.network_config.subnet) || job.output.contains('MASQUERADE')

	println('✓ NAT rules test passed')
}

// Test 3: IP allocation sequential
fn test_ip_allocation_sequential() ! {
	skip_if_not_linux()

	test_name := 'test_ip_seq_${os.getpid()}'
	defer { cleanup_test_heropods(test_name) }

	mut hp := new(
		name:       test_name
		reset:      false // Don't reset to avoid race conditions with parallel tests
		use_podman: true  // Skip default image setup in tests
	)!

	// Allocate multiple IPs
	mut allocated_ips := []string{}
	for i in 0 .. 10 {
		ip := hp.network_allocate_ip('container_${i}')!
		allocated_ips << ip
	}

	// Verify all IPs are unique
	for i, ip1 in allocated_ips {
		for j, ip2 in allocated_ips {
			if i != j {
				assert ip1 != ip2, 'IPs should be unique: ${ip1} == ${ip2}'
			}
		}
	}

	// Verify all IPs are in correct subnet
	for ip in allocated_ips {
		assert ip.starts_with('10.10.0.')
	}

	println('✓ IP allocation sequential test passed')
}

// Test 4: IP pool management with container lifecycle
fn test_ip_pool_management() ! {
	skip_if_not_linux()
	setup_test_rootfs()!

	test_name := 'test_ip_pool_${os.getpid()}'
	defer { cleanup_test_heropods(test_name) }

	mut hp := new(
		name:       test_name
		reset:      false // Don't reset to avoid race conditions with parallel tests
		use_podman: true  // Skip default image setup in tests
	)!

	// Create and start 3 containers with custom Alpine image
	mut container1 := hp.container_new(
		name:              'pool_test1_${os.getpid()}'
		image:             .custom
		custom_image_name: 'alpine_pool1'
		docker_url:        'docker.io/library/alpine:3.20'
	)!
	mut container2 := hp.container_new(
		name:              'pool_test2_${os.getpid()}'
		image:             .custom
		custom_image_name: 'alpine_pool2'
		docker_url:        'docker.io/library/alpine:3.20'
	)!
	mut container3 := hp.container_new(
		name:              'pool_test3_${os.getpid()}'
		image:             .custom
		custom_image_name: 'alpine_pool3'
		docker_url:        'docker.io/library/alpine:3.20'
	)!

	// Start with keep_alive to prevent Alpine's /bin/sh from exiting immediately
	container1.start(keep_alive: true)!
	container2.start(keep_alive: true)!
	container3.start(keep_alive: true)!

	// Get allocated IPs
	ip1 := hp.network_config.allocated_ips[container1.name]
	ip2 := hp.network_config.allocated_ips[container2.name]
	ip3 := hp.network_config.allocated_ips[container3.name]

	// Delete middle container (frees IP2)
	container2.stop()!
	container2.delete()!

	// Verify IP2 is freed
	assert container2.name !in hp.network_config.allocated_ips

	// Create new container - should reuse freed IP2
	mut container4 := hp.container_new(
		name:              'pool_test4_${os.getpid()}'
		image:             .custom
		custom_image_name: 'alpine_pool4'
		docker_url:        'docker.io/library/alpine:3.20'
	)!
	container4.start(keep_alive: true)!

	ip4 := hp.network_config.allocated_ips[container4.name]
	assert ip4 == ip2, 'Should reuse freed IP: ${ip2} vs ${ip4}'

	// Cleanup
	container1.stop()!
	container1.delete()!
	container3.stop()!
	container3.delete()!
	container4.stop()!
	container4.delete()!

	println('✓ IP pool management test passed')
}

// Test 5: Custom bridge configuration
fn test_custom_bridge_config() ! {
	skip_if_not_linux()

	test_name := 'test_custom_br_${os.getpid()}'
	custom_bridge := 'custombr_${os.getpid()}'
	defer {
		cleanup_test_heropods(test_name)
		// Cleanup custom bridge
		osal.exec(cmd: 'ip link delete ${custom_bridge}') or {}
	}

	mut hp := new(
		name:        test_name
		reset:       false // Don't reset to avoid race conditions with parallel tests
		use_podman:  true  // Skip default image setup in tests
		bridge_name: custom_bridge
		subnet:      '172.20.0.0/24'
		gateway_ip:  '172.20.0.1'
	)!

	// Verify custom bridge exists
	job := osal.exec(cmd: 'ip link show ${custom_bridge}')!
	assert job.output.contains(custom_bridge)

	// Verify custom IP
	job2 := osal.exec(cmd: 'ip addr show ${custom_bridge}')!
	assert job2.output.contains('172.20.0.1')

	println('✓ Custom bridge configuration test passed')
}
