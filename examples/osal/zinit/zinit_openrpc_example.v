module main

import incubaid.herolib.osal.zinit
import json

fn main() {
	// Create a new Zinit client with the default socket path
	mut zinit_client := zinit.new_stateless(socket_path: '/tmp/zinit.sock')!

	println('Connected to Zinit via OpenRPC')

	// Example 1: Get the OpenRPC API specification
	println('\n=== Getting API Specification ===')
	api_spec := zinit_client.client.discover() or {
		println('Error getting API spec: ${err}')
		return
	}
	println('API Specification (first 100 chars): ${api_spec[..100]}...')

	// Example 2: List all services
	println('\n=== Listing Services ===')
	service_list := zinit_client.client.list() or {
		println('Error listing services: ${err}')
		return
	}
	println('Services:')
	for name, state in service_list {
		println('- ${name}: ${state}')
	}

	// Example 3: Get detailed status of a service (if any exist)
	if service_list.len > 0 {
		service_name := service_list.keys()[0]
		println('\n=== Getting Status for Service: ${service_name} ===')

		status := zinit_client.client.status(service_name) or {
			println('Error getting status: ${err}')
			return
		}

		println('Service Status:')
		println('- Name: ${status.name}')
		println('- PID: ${status.pid}')
		println('- State: ${status.state}')
		println('- Target: ${status.target}')
		println('- Dependencies:')
		for dep_name, dep_state in status.after {
			println('  - ${dep_name}: ${dep_state}')
		}

		// Example 4: Get service stats
		println('\n=== Getting Stats for Service: ${service_name} ===')
		stats := zinit_client.client.stats(service_name) or {
			println('Error getting stats: ${err}')
			println('Note: Stats are only available for running services')
			return
		}

		println('Service Stats:')
		println('- Memory Usage: ${stats.memory_usage} bytes')
		println('- CPU Usage: ${stats.cpu_usage}%')
		if stats.children.len > 0 {
			println('- Child Processes:')
			for child in stats.children {
				println('  - PID: ${child.pid}, Memory: ${child.memory_usage} bytes, CPU: ${child.cpu_usage}%')
			}
		}
	} else {
		println('\nNo services found to query')
	}

	// Example 5: Create a new service (commented out for safety)
	/*
	println('\n=== Creating a New Service ===')
	new_service_config := zinit.ServiceConfig{
		exec: '/bin/echo "Hello from Zinit"'
		oneshot: true
		after: []string{}
		log: 'stdout'
		env: {
			'ENV_VAR': 'value'
		}
	}
	
	result := zinit_client.client.create_service('example_service', new_service_config) or {
		println('Error creating service: ${err}')
		return
	}
	println('Service created: ${result}')
	
	// Start the service
	zinit_client.client.start('example_service') or {
		println('Error starting service: ${err}')
		return
	}
	println('Service started')
	
	// Get logs
	logs := zinit_client.client.get_logs('example_service') or {
		println('Error getting logs: ${err}')
		return
	}
	println('Service logs:')
	for log in logs {
		println('- ${log}')
	}
	
	// Delete the service when done
	zinit_client.client.stop('example_service') or {
		println('Error stopping service: ${err}')
		return
	}
	time.sleep(1 * time.second)
	zinit_client.client.forget('example_service') or {
		println('Error forgetting service: ${err}')
		return
	}
	zinit_client.client.delete_service('example_service') or {
		println('Error deleting service: ${err}')
		return
	}
	println('Service deleted')
	*/

	println('\nZinit OpenRPC client example completed')
}
