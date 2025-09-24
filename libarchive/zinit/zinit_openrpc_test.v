module zinit

import freeflowuniverse.herolib.schemas.jsonrpc
import os
import rand
import time

// These tests require a running Zinit instance with the Unix socket at /tmp/zinit.sock
// If Zinit is not running, the tests will be skipped

fn test_client_creation() {
	if !os.exists('/tmp/zinit.sock') {
		println('Skipping test: Zinit socket not found at /tmp/zinit.sock')
		return
	}

	client := new_client('/tmp/zinit.sock')
	assert client.rpc_client != unsafe { nil }
}

fn test_service_list() {
	if !os.exists('/tmp/zinit.sock') {
		println('Skipping test: Zinit socket not found at /tmp/zinit.sock')
		return
	}

	mut client := new_client('/tmp/zinit.sock')
	services := client.list() or {
		assert false, 'Failed to list services: ${err}'
		return
	}

	// Just verify we got a map, even if it's empty
	assert typeof(services).name == 'map[string]string'
	println('Found ${services.len} services')
}

fn test_discover() {
	if !os.exists('/tmp/zinit.sock') {
		println('Skipping test: Zinit socket not found at /tmp/zinit.sock')
		return
	}

	mut client := new_client('/tmp/zinit.sock')
	spec := client.discover() or {
		assert false, 'Failed to get OpenRPC spec: ${err}'
		return
	}

	// Verify we got a non-empty string
	assert spec.len > 0
	assert spec.contains('"openrpc"')
	assert spec.contains('"methods"')
}

fn test_stateless_client() {
	if !os.exists('/tmp/zinit.sock') {
		println('Skipping test: Zinit socket not found at /tmp/zinit.sock')
		return
	}

	// Create temporary directories for testing
	temp_dir := os.temp_dir()
	path := os.join_path(temp_dir, 'zinit_test')
	pathcmds := os.join_path(temp_dir, 'zinit_test_cmds')

	// Create the directories
	os.mkdir_all(path) or {
		assert false, 'Failed to create test directory: ${err}'
		return
	}
	os.mkdir_all(pathcmds) or {
		assert false, 'Failed to create test commands directory: ${err}'
		return
	}

	// Clean up after the test
	defer {
		os.rmdir_all(path) or {}
		os.rmdir_all(pathcmds) or {}
	}

	mut zinit_client := new_stateless(
		socket_path: '/tmp/zinit.sock'
		path:        path
		pathcmds:    pathcmds
	) or {
		assert false, 'Failed to create stateless client: ${err}'
		return
	}

	// Test the names method which uses the client
	names := zinit_client.names() or {
		assert false, 'Failed to get service names: ${err}'
		return
	}

	assert typeof(names).name == '[]string'
}

// This test creates a test service, starts it, checks its status, and then cleans up
// It's commented out by default to avoid modifying the system
/*
fn test_service_lifecycle() {
	if !os.exists('/tmp/zinit.sock') {
		println('Skipping test: Zinit socket not found at /tmp/zinit.sock')
		return
	}

	service_name := 'test_service_${rand.int_in_range(1000, 9999)}'
	mut client := new_client('/tmp/zinit.sock')
	
	// Create service config
	config := ServiceConfig{
		exec: '/bin/echo "Test service running"'
		oneshot: true
		after: []string{}
		log: 'stdout'
		env: {
			'TEST_VAR': 'test_value'
		}
	}
	
	// Create the service
	client.create_service(service_name, config) or {
		assert false, 'Failed to create service: ${err}'
		return
	}
	
	// Monitor the service
	client.monitor(service_name) or {
		assert false, 'Failed to monitor service: ${err}'
		return
	}
	
	// Start the service
	client.start(service_name) or {
		assert false, 'Failed to start service: ${err}'
		return
	}
	
	// Check service status
	status := client.status(service_name) or {
		assert false, 'Failed to get service status: ${err}'
		return
	}
	
	assert status.name == service_name
	
	// Clean up
	client.stop(service_name) or {
		println('Warning: Failed to stop service: ${err}')
	}
	
	time.sleep(1 * time.second)
	
	client.forget(service_name) or {
		println('Warning: Failed to forget service: ${err}')
	}
	
	client.delete_service(service_name) or {
		println('Warning: Failed to delete service: ${err}')
	}
}
*/
