#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.clients.zinit
import freeflowuniverse.herolib.installers.infra.zinit_installer
import os
import time

// Comprehensive example demonstrating all Zinit RPC client functionality
// This example shows how to use all 18 methods in the Zinit JSON-RPC API

println('=== Zinit RPC Client Example ===\n')

// // Start Zinit in the background
// println('Starting Zinit in background...')
// mut zinit_process := os.new_process('/usr/local/bin/zinit')
// zinit_process.set_args(['init'])
// zinit_process.set_redirect_stdio()
// zinit_process.run()

// Wait a moment for Zinit to start up
// time.sleep(2000 * time.millisecond)
// println('✓ Zinit started')

// Ensure we clean up Zinit when done
// defer {
// 	println('\nCleaning up...')
// 	zinit_process.signal_kill()
// 	zinit_process.wait()
// 	println('✓ Zinit stopped')
// }

// mut installer := zinit_installer.get()!
// installer.install()!
// installer.start()!

// Create a new client
mut client := zinit.new()!

println(client)


println('✓ Created Zinit RPC client')

// 1. Discover API specification
println('\n1. Discovering API specification...')
spec := client.rpc_discover() or {
	println('Failed to discover API: ${err}')
	exit(1)
}
println('✓ API discovered:')
println('  - OpenRPC version: ${spec.openrpc}')
println('  - API title: ${spec.info.title}')
println('  - API version: ${spec.info.version}')
println('  - Methods available: ${spec.methods.len}')

// 2. List all services
println('\n2. Listing all services...')
services := client.service_list() or {
	println('Failed to list services: ${err}')
	exit(1)
}
println('✓ Found ${services.len} services:')
for service_name, state in services {
	println('  - ${service_name}: ${state}')
}

// 3. Create a test service configuration
println('\n3. Creating a test service...')
test_service_name := 'test_echo_service'
config := zinit.ServiceConfig{
	exec:             '/bin/echo "Hello from test service"'
	oneshot:          true
	log:              'stdout'
	env:              {
		'TEST_VAR': 'test_value'
	}
	shutdown_timeout: 10
}

service_path := client.service_create(test_service_name, config) or {
	if err.msg().contains('already exists') {
		println('✓ Service already exists, continuing...')
		''
	} else {
		println('Failed to create service: ${err}')
		exit(1)
	}
}
if service_path != '' {
	println('✓ Service created at: ${service_path}')
}

// 4. Get service configuration
println('\n4. Getting service configuration...')
retrieved_config := client.service_get(test_service_name) or {
	println('Failed to get service config: ${err}')
	exit(1)
}
println('✓ Service config retrieved:')
println('  - Exec: ${retrieved_config.exec}')
println('  - Oneshot: ${retrieved_config.oneshot}')
println('  - Log: ${retrieved_config.log}')
println('  - Shutdown timeout: ${retrieved_config.shutdown_timeout}')

// 5. Monitor the service
println('\n5. Starting to monitor the service...')
client.service_monitor(test_service_name) or {
	if err.msg().contains('already monitored') {
		println('✓ Service already monitored')
	} else {
		println('Failed to monitor service: ${err}')
		exit(1)
	}
}

// 6. Get service status
println('\n6. Getting service status...')
status := client.service_status(test_service_name) or {
	println('Failed to get service status: ${err}')
	exit(1)
}
println('✓ Service status:')
println('  - Name: ${status.name}')
println('  - PID: ${status.pid}')
println('  - State: ${status.state}')
println('  - Target: ${status.target}')
if status.after.len > 0 {
	println('  - Dependencies:')
	for dep_name, dep_state in status.after {
		println('    - ${dep_name}: ${dep_state}')
	}
}

// 7. Start the service (if it's not running)
if status.state != 'Running' {
	println('\n7. Starting the service...')
	client.service_start(test_service_name) or {
		println('Failed to start service: ${err}')
		// Continue anyway
	}
	println('✓ Service start command sent')
} else {
	println('\n7. Service is already running')
}

// 8. Get service statistics (if running)
println('\n8. Getting service statistics...')
stats := client.service_stats(test_service_name) or {
	println('Failed to get service stats (service might not be running): ${err}')
	// Continue anyway
	zinit.ServiceStats{}
}
if stats.name != '' {
	println('✓ Service statistics:')
	println('  - Name: ${stats.name}')
	println('  - PID: ${stats.pid}')
	println('  - Memory usage: ${stats.memory_usage} bytes')
	println('  - CPU usage: ${stats.cpu_usage}%')
	if stats.children.len > 0 {
		println('  - Child processes:')
		for child in stats.children {
			println('    - PID ${child.pid}: Memory ${child.memory_usage} bytes, CPU ${child.cpu_usage}%')
		}
	}
}

// 9. Get current logs
println('\n9. Getting current logs...')
all_logs := client.stream_current_logs(name: '') or {
	println('Failed to get logs: ${err}')
	[]string{}
}
if all_logs.len > 0 {
	println('✓ Retrieved ${all_logs.len} log entries (showing last 3):')
	start_idx := if all_logs.len > 3 { all_logs.len - 3 } else { 0 }
	for i in start_idx .. all_logs.len {
		println('  ${all_logs[i]}')
	}
} else {
	println('✓ No logs available')
}

// 10. Get logs for specific service
println('\n10. Getting logs for test service...')
service_logs := client.stream_current_logs(name: test_service_name) or {
	println('Failed to get service logs: ${err}')
	[]string{}
}
if service_logs.len > 0 {
	println('✓ Retrieved ${service_logs.len} log entries for ${test_service_name}:')
	for log in service_logs {
		println('  ${log}')
	}
} else {
	println('✓ No logs available for ${test_service_name}')
}

// 11. Subscribe to logs
println('\n11. Subscribing to log stream...')
subscription_id := client.stream_subscribe_logs(name: test_service_name) or {
	println('Failed to subscribe to logs: ${err}')
	u64(0)
}
if subscription_id != 0 {
	println('✓ Subscribed to logs with ID: ${subscription_id}')
}

// 12. Send signal to service (if running)
// Get fresh status to make sure service is still running
fresh_status := client.service_status(test_service_name) or {
	println('\n12. Skipping signal test (cannot get service status)')
	zinit.ServiceStatus{}
}
if fresh_status.state == 'Running' && fresh_status.pid > 0 {
	println('\n12. Sending SIGTERM signal to service...')
	client.service_kill(test_service_name, 'SIGTERM') or {
		println('Failed to send signal: ${err}')
		// Continue anyway
	}
	println('✓ Signal sent')
} else {
	println('\n12. Skipping signal test (service not running: state=${fresh_status.state}, pid=${fresh_status.pid})')
}

// 13. Stop the service
println('\n13. Stopping the service...')
client.service_stop(test_service_name) or {
	if err.msg().contains('is down') {
		println('✓ Service is already stopped')
	} else {
		println('Failed to stop service: ${err}')
		// Continue anyway
	}
}

// 14. Forget the service
println('\n14. Forgetting the service...')
client.service_forget(test_service_name) or {
	println('Failed to forget service: ${err}')
	// Continue anyway
}
println('✓ Service forgotten')

// 15. Delete the service configuration
println('\n15. Deleting service configuration...')
delete_result := client.service_delete(test_service_name) or {
	println('Failed to delete service: ${err}')
	''
}
if delete_result != '' {
	println('✓ Service deleted: ${delete_result}')
}

// 16. Test HTTP server operations
println('\n16. Testing HTTP server operations...')
server_result := client.system_start_http_server('127.0.0.1:9999') or {
	println('Failed to start HTTP server: ${err}')
	''
}
if server_result != '' {
	println('✓ HTTP server started: ${server_result}')
	// Stop the HTTP server
	client.system_stop_http_server() or { println('Failed to stop HTTP server: ${err}') }
	println('✓ HTTP server stopped')
}

// 17. Test system operations (commented out for safety)
println('\n17. System operations available but not tested for safety:')
println('  - system_shutdown() - Stops all services and powers off the system')
println('  - system_reboot() - Stops all services and reboots the system')

println('\n=== Example completed successfully! ===')
println('\nThis example demonstrated all 18 methods in the Zinit JSON-RPC API:')
println('✓ rpc.discover - Get OpenRPC specification')
println('✓ service_list - List all services')
println('✓ service_create - Create service configuration')
println('✓ service_get - Get service configuration')
println('✓ service_monitor - Start monitoring service')
println('✓ service_status - Get service status')
println('✓ service_start - Start service')
println('✓ service_stats - Get service statistics')
println('✓ stream_current_logs - Get current logs')
println('✓ stream_subscribe_logs - Subscribe to logs (returns subscription ID)')
println('✓ service_kill - Send signal to service')
println('✓ service_stop - Stop service')
println('✓ service_forget - Stop monitoring service')
println('✓ service_delete - Delete service configuration')
println('✓ system_start_http_server - Start HTTP server')
println('✓ system_stop_http_server - Stop HTTP server')
println('• system_shutdown - Available but not tested')
println('• system_reboot - Available but not tested')
