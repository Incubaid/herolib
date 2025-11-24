module heropods

import incubaid.herolib.core
import incubaid.herolib.osal.core as osal
import os

// Simplified test suite for HeroPods container management
//
// These tests use real Docker images (Alpine Linux) for reliability
// Prerequisites: Linux, crun, podman, ip, iptables, nsenter

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

// Cleanup helper for tests - stops and deletes all containers
fn cleanup_test_heropods(name string) {
	mut hp := get(name: name) or { return }

	// Stop and delete all containers
	for container_name, mut container in hp.containers {
		container.stop() or {}
		container.delete() or {}
	}

	// Cleanup network - don't delete the bridge (false) - tests run in parallel
	hp.network_cleanup_all(false) or {}

	// Delete from factory
	delete(name: name) or {}
}

// Test 1: HeroPods initialization and configuration
fn test_heropods_initialization() ! {
	skip_if_not_linux()

	test_name := 'test_init_${os.getpid()}'
	defer {
		cleanup_test_heropods(test_name)
	}

	mut hp := new(
		name:       test_name
		reset:      true
		use_podman: true // Skip default image setup in tests
	)!

	assert hp.base_dir != ''
	assert hp.network_config.bridge_name == 'heropods0'
	assert hp.network_config.subnet == '10.10.0.0/24'
	assert hp.network_config.gateway_ip == '10.10.0.1'
	assert hp.network_config.dns_servers.len > 0
	assert hp.name == test_name

	println('✓ HeroPods initialization test passed')
}

// Test 2: Custom network configuration
fn test_custom_network_config() ! {
	skip_if_not_linux()

	test_name := 'test_custom_net_${os.getpid()}'
	defer { cleanup_test_heropods(test_name) }

	mut hp := new(
		name:        test_name
		reset:       true
		use_podman:  true // Skip default image setup in tests
		bridge_name: 'testbr0'
		subnet:      '192.168.100.0/24'
		gateway_ip:  '192.168.100.1'
		dns_servers: ['1.1.1.1', '1.0.0.1']
	)!

	assert hp.network_config.bridge_name == 'testbr0'
	assert hp.network_config.subnet == '192.168.100.0/24'
	assert hp.network_config.gateway_ip == '192.168.100.1'
	assert hp.network_config.dns_servers == ['1.1.1.1', '1.0.0.1']

	println('✓ Custom network configuration test passed')
}

// Test 3: Pull Docker image and create container
fn test_container_creation_with_docker_image() ! {
	skip_if_not_linux()

	test_name := 'test_docker_${os.getpid()}'
	defer {
		cleanup_test_heropods(test_name)
	}

	mut hp := new(
		name:       test_name
		reset:      true
		use_podman: true
	)!

	container_name := 'alpine_${os.getpid()}'

	// Pull Alpine Linux image from Docker Hub (very small, ~7MB)
	mut container := hp.container_new(
		name:              container_name
		image:             .custom
		custom_image_name: 'alpine_test'
		docker_url:        'docker.io/library/alpine:3.20'
	)!

	assert container.name == container_name
	assert container.factory.name == test_name
	assert container_name in hp.containers

	// Verify rootfs was extracted
	rootfs_path := '${hp.base_dir}/images/alpine_test/rootfs'
	assert os.is_dir(rootfs_path)
	// Alpine uses busybox, check for bin directory and basic structure
	assert os.is_dir('${rootfs_path}/bin')
	assert os.is_dir('${rootfs_path}/etc')

	println('✓ Docker image pull and container creation test passed')
}

// Test 4: Container lifecycle with real Docker image (start, status, stop, delete)
fn test_container_lifecycle() ! {
	skip_if_not_linux()

	test_name := 'test_lifecycle_${os.getpid()}'
	defer {
		cleanup_test_heropods(test_name)
	}

	mut hp := new(
		name:       test_name
		reset:      true
		use_podman: true
	)!

	container_name := 'lifecycle_${os.getpid()}'
	mut container := hp.container_new(
		name:              container_name
		image:             .custom
		custom_image_name: 'alpine_lifecycle'
		docker_url:        'docker.io/library/alpine:3.20'
	)!

	// Test start
	container.start()!
	status := container.status()!
	assert status == .running

	// Verify container has a PID
	pid := container.pid()!
	assert pid > 0

	// Test stop
	container.stop()!
	status_after_stop := container.status()!
	assert status_after_stop == .stopped

	// Test delete
	container.delete()!
	exists := container.container_exists_in_crun()!
	assert !exists

	println('✓ Container lifecycle test passed')
}

// Test 5: Container command execution with real Alpine image
fn test_container_exec() ! {
	skip_if_not_linux()

	test_name := 'test_exec_${os.getpid()}'
	defer {
		cleanup_test_heropods(test_name)
	}

	mut hp := new(
		name:       test_name
		reset:      true
		use_podman: true
	)!

	container_name := 'exec_${os.getpid()}'
	mut container := hp.container_new(
		name:              container_name
		image:             .custom
		custom_image_name: 'alpine_exec'
		docker_url:        'docker.io/library/alpine:3.20'
	)!

	container.start()!
	defer {
		container.stop() or {}
		container.delete() or {}
	}

	// Execute simple echo command
	result := container.exec(cmd: 'echo "test123"')!
	assert result.contains('test123')

	// Execute pwd command
	result2 := container.exec(cmd: 'pwd')!
	assert result2.contains('/')

	// Execute ls command (Alpine has busybox ls)
	result3 := container.exec(cmd: 'ls /')!
	assert result3.contains('bin')
	assert result3.contains('etc')

	println('✓ Container exec test passed')
}

// Test 6: Network IP allocation (without starting containers)
fn test_network_ip_allocation() ! {
	skip_if_not_linux()

	test_name := 'test_ip_alloc_${os.getpid()}'
	defer {
		cleanup_test_heropods(test_name)
	}

	mut hp := new(
		name:       test_name
		reset:      true
		use_podman: true
	)!

	// Allocate IPs for multiple containers (without starting them)
	ip1 := hp.network_allocate_ip('container1')!
	ip2 := hp.network_allocate_ip('container2')!
	ip3 := hp.network_allocate_ip('container3')!

	// Verify IPs are different
	assert ip1 != ip2
	assert ip2 != ip3
	assert ip1 != ip3

	// Verify IPs are in correct subnet
	assert ip1.starts_with('10.10.0.')
	assert ip2.starts_with('10.10.0.')
	assert ip3.starts_with('10.10.0.')

	// Verify IPs are tracked
	assert 'container1' in hp.network_config.allocated_ips
	assert 'container2' in hp.network_config.allocated_ips
	assert 'container3' in hp.network_config.allocated_ips

	println('✓ Network IP allocation test passed')
}

// Test 7: IPv4 connectivity test with real Alpine container
fn test_ipv4_connectivity() ! {
	skip_if_not_linux()

	test_name := 'test_ipv4_${os.getpid()}'
	defer {
		cleanup_test_heropods(test_name)
	}

	mut hp := new(
		name:       test_name
		reset:      true
		use_podman: true
	)!

	container_name := 'ipv4_${os.getpid()}'
	mut container := hp.container_new(
		name:              container_name
		image:             .custom
		custom_image_name: 'alpine_ipv4'
		docker_url:        'docker.io/library/alpine:3.20'
	)!

	container.start()!
	defer {
		container.stop() or {}
		container.delete() or {}
	}

	// Check container has an IP address
	container_ip := hp.network_config.allocated_ips[container_name] or {
		return error('Container should have allocated IP')
	}
	assert container_ip.starts_with('10.10.0.')

	// Test IPv4 connectivity by checking the container's IP configuration
	result := container.exec(cmd: 'ip addr show eth0')!
	assert result.contains(container_ip)
	assert result.contains('eth0')

	// Test that default route exists
	route_result := container.exec(cmd: 'ip route')!
	assert route_result.contains('default')
	assert route_result.contains('10.10.0.1')

	println('✓ IPv4 connectivity test passed')
}

// Test 8: Container deletion and IP cleanup
fn test_container_deletion() ! {
	skip_if_not_linux()

	test_name := 'test_delete_${os.getpid()}'
	defer {
		cleanup_test_heropods(test_name)
	}

	mut hp := new(
		name:       test_name
		reset:      true
		use_podman: true
	)!

	container_name := 'delete_${os.getpid()}'
	mut container := hp.container_new(
		name:              container_name
		image:             .custom
		custom_image_name: 'alpine_delete'
		docker_url:        'docker.io/library/alpine:3.20'
	)!

	// Start container (allocates IP)
	container.start()!

	// Verify IP is allocated
	assert container_name in hp.network_config.allocated_ips

	// Stop and delete container
	container.stop()!
	container.delete()!

	// Verify container is deleted from crun
	exists := container.container_exists_in_crun()!
	assert !exists

	// Verify IP is freed
	assert container_name !in hp.network_config.allocated_ips

	println('✓ Container deletion and IP cleanup test passed')
}
