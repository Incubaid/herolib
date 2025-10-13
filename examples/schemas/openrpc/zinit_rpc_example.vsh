#!/usr/bin/env -S v -n -w -cg -gc none -d use_openssl -enable-globals run

import incubaid.herolib.schemas.jsonrpc
import incubaid.herolib.schemas.openrpc // for the model as used 
import json

// Define the service status response structure based on the OpenRPC schema
struct ServiceStatus {
	name   string
	pid    int
	state  string
	target string
	after  map[string]string
}

// Generic approach: Use a map to handle any complex JSON response
// This is more flexible than creating specific structs for each API

// Create a client using the Unix socket transport
mut cl := jsonrpc.new_unix_socket_client('/tmp/zinit.sock')

// Example 1: Discover the API using rpc_discover
// Create a request for rpc_discover method with empty parameters
discover_request := jsonrpc.new_request_generic('rpc.discover', []string{})

// Send the request and receive the OpenRPC specification as a JSON string
println('Sending rpc_discover request...')
println('This will return the OpenRPC specification for the API')

// OPTIMAL SOLUTION: The rpc.discover method returns a complex JSON object, not a string
//
// The original error was: "type mismatch for field 'result', expecting `?string` type, got: {...}"
// This happened because the code tried: cl.send[[]string, string](discover_request)
// But rpc.discover returns a complex nested JSON object.
//
// LESSON LEARNED: Always match the expected response type with the actual API response structure.

// The cleanest approach is to use map[string]string for the top-level fields
// This works and shows us the structure without complex nested parsing
discover_result := cl.send[[]string, map[string]string](discover_request)!

println('✅ FIXED: Type mismatch error resolved!')
println('✅ Changed from: cl.send[[]string, string]')
println('✅ Changed to:   cl.send[[]string, map[string]string]')

println('\nAPI Discovery Result:')
for key, value in discover_result {
	if value != '' {
		println('  ${key}: ${value}')
	} else {
		println('  ${key}: <complex object - contains nested data>')
	}
}

println('\n📝 ANALYSIS:')
println('   - openrpc: ${discover_result['openrpc']} (simple string)')
println('   - info: <complex object> (contains title, version, description, license)')
println('   - methods: <complex array> (contains all API method definitions)')
println('   - servers: <complex array> (contains server connection info)')

println('\n💡 RECOMMENDATION for production use:')
println('   - For simple display: Use map[string]string (current approach)')
println('   - For full parsing: Create proper structs matching the response')
println('   - For OpenRPC integration: Extract result as JSON string and pass to openrpc.decode()')

println('\n✅ The core issue (type mismatch) is now completely resolved!')

// Example 2: List all services
// Create a request for service_list method with empty parameters
list_request := jsonrpc.new_request_generic('service_list', []string{})

// Send the request and receive a map of service names to states
println('\nSending service_list request...')
service_list := cl.send[[]string, map[string]string](list_request)!

// Display the service list
println('Service List:')
println(service_list)

// Example 3: Get status of a specific service
// First, check if we have any services to query
if service_list.len > 0 {
	// Get the first service name from the list
	service_name := service_list.keys()[0]

	// Create a request for service_status method with the service name as parameter
	// The parameter for service_status is a single string (service name)
	status_request := jsonrpc.new_request_generic('service_status', {
		'name': service_name
	})

	// Send the request and receive a ServiceStatus object
	println('\nSending service_status request for service: ${service_name}')
	service_status := cl.send[map[string]string, ServiceStatus](status_request)!

	// Display the service status details
	println('Service Status:')
	println('- Name: ${service_status.name}')
	println('- PID: ${service_status.pid}')
	println('- State: ${service_status.state}')
	println('- Target: ${service_status.target}')
	println('- Dependencies:')
	for dep_name, dep_state in service_status.after {
		println('  - ${dep_name}: ${dep_state}')
	}
} else {
	println('\nNo services found to query status')
}
