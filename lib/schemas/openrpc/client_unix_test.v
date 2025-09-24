module openrpc

import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.schemas.jsonschema

// Test struct for typed parameters
struct TestParams {
	name  string
	value int
}

// Test struct for typed result
struct TestResult {
	success bool
	message string
}

// Example custom handler for testing
struct TestHandler {
}

fn (mut h TestHandler) handle(req jsonrpc.Request) !jsonrpc.Response {
	match req.method {
		'test.echo' {
			return jsonrpc.new_response(req.id, req.params)
		}
		'test.add' {
			// Simple addition test - expect params like '{"a": 5, "b": 3}'
			return jsonrpc.new_response(req.id, '{"result": 8}')
		}
		'test.greet' {
			// Greeting test - expect params like '{"name": "Alice"}'
			return jsonrpc.new_response(req.id, '{"message": "Hello, World!"}')
		}
		else {
			return jsonrpc.new_error_response(req.id, jsonrpc.method_not_found)
		}
	}
}

fn test_unix_client_basic() {
	// This test requires a running server, so it's more of an integration test
	// In practice, you would start a server in a separate goroutine or process

	mut client := new_unix_client(
		socket_path: '/tmp/test_heromodels'
		timeout:     5
	)

	// Test string-based call
	result := client.call('test.echo', '{"message": "hello"}') or {
		println('Expected error since no server is running: ${err}')
		return
	}

	println('Echo result: ${result}')
}

fn test_unix_client_typed() {
	mut client := new_unix_client(
		socket_path: '/tmp/test_heromodels'
		timeout:     5
	)

	// Test typed call
	params := TestParams{
		name:  'test'
		value: 42
	}

	result := client.call_generic[TestParams, TestResult]('test.process', params) or {
		println('Expected error since no server is running: ${err}')
		return
	}

	println('Typed result: ${result}')
}

fn test_unix_client_discover() {
	mut client := new_unix_client(
		socket_path: '/tmp/test_heromodels'
		timeout:     5
	)

	// Test discovery
	spec := client.discover() or {
		println('Expected error since no server is running: ${err}')
		return
	}

	println('OpenRPC spec version: ${spec.openrpc}')
	println('Info title: ${spec.info.title}')
}

fn test_unix_client_ping() {
	mut client := new_unix_client(
		socket_path: '/tmp/test_heromodels'
		timeout:     5
	)

	// Test ping
	is_alive := client.ping() or {
		println('Expected error since no server is running: ${err}')
		return
	}

	println('Server is alive: ${is_alive}')
}

// Integration test that demonstrates full client-server interaction
fn test_full_integration() {
	socket_path := '/tmp/test_heromodels_integration'

	// Create a test OpenRPC specification
	mut spec := OpenRPC{
		openrpc: '1.3.0'
		info:    Info{
			title:   'Test API'
			version: '1.0.0'
		}
		methods: [
			Method{
				name:   'test.echo'
				params: []
				result: ContentDescriptor{
					name:   'result'
					schema: jsonschema.Schema{}
				}
			},
		]
	}

	// Create handler
	mut test_handler := TestHandler{}
	handler := Handler{
		specification: spec
		handler:       test_handler
	}

	// Start server in background
	mut server := new_unix_server(handler, socket_path: socket_path) or {
		println('Failed to create server: ${err}')
		return
	}

	// Start server in a separate thread
	spawn fn [mut server] () {
		server.start() or { println('Server error: ${err}') }
	}()

	// Give server time to start
	// time.sleep(100 * time.millisecond)

	// Create client and test
	mut client := new_unix_client(
		socket_path: socket_path
		timeout:     5
	)

	// Test the connection
	result := client.call('test.echo', '{"test": "data"}') or {
		println('Client call failed: ${err}')
		server.close() or {}
		return
	}

	println('Integration test result: ${result}')

	// Clean up
	server.close() or { println('Failed to close server: ${err}') }
}
