module openrpc

import time
import json
import x.json2
import net.unix
import os
import incubaid.herolib.ui.console
import incubaid.herolib.schemas.jsonrpc

const testdata_dir = os.join_path(os.dir(@FILE), 'testdata')
const openrpc_path = os.join_path(testdata_dir, 'openrpc.json')

pub fn test_new_unix_server() ! {
	mut spec := OpenRPC{}
	handler := Handler{
		specification: new(path: openrpc_path)!
	}
	mut server := new_unix_server(handler)!

	defer {
		server.close() or { panic(err) }
	}

	spawn server.start()

	// client()
}

// pub fn test_unix_server_start() ! {
// 	mut spec := OpenRPC{}
// 	handler := Handler{
// 		specification: new(path: openrpc_path)!
// 	}
// 	mut server := new_unix_server(handler)!

// 	defer {
// 		server.close() or {panic(err)}
// 	}

// 	spawn server.start()

// 	// client()
// }

pub fn test_unix_server_handle_connection() ! {
	mut spec := OpenRPC{}
	handler := Handler{
		specification: new(path: openrpc_path)!
	}
	mut server := new_unix_server(handler)!

	// Start server in background
	spawn server.start()

	// Give server time to start
	time.sleep(50 * time.millisecond)

	// Connect to the server
	mut conn := unix.connect_stream(server.socket_path)!

	defer {
		conn.close() or { panic(err) }
		server.close() or { panic(err) }
	}
	println('Connected to server at ${server.socket_path}')

	// Test 1: Send rpc.discover request
	discover_request := jsonrpc.new_request('rpc.discover', '')
	request_json := discover_request.encode()

	// Send the request
	conn.write_string(request_json)!

	// Read the response
	mut buffer := []u8{len: 4096}
	bytes_read := conn.read(mut buffer)!
	response_data := buffer[..bytes_read].bytestr()

	// Parse and validate response
	response := jsonrpc.decode_response(response_data)!
	assert response.id == discover_request.id
	assert response.is_result()
	assert !response.is_error()

	// Validate that the result contains OpenRPC specification
	result := response.result()!
	assert result.len > 0

	// Test 2: Send invalid JSON request
	invalid_request := '{"invalid": "json"}'
	conn.write_string(invalid_request)!

	// Set a short read timeout to test no response behavior
	conn.set_read_timeout(10 * time.millisecond)

	// Try to read response - should timeout since server sends no response for invalid JSON
	conn.wait_for_read() or {
		// This is expected behavior - server should not respond to invalid JSON without extractable ID
		console.print_debug('Expected timeout for invalid JSON request: ${err}')
		assert err.msg().contains('timeout') || err.msg().contains('timed out')
		// Reset timeout for next test
		conn.set_read_timeout(30 * time.second)
	}

	// Test 3: Send request with non-existent method
	nonexistent_request := jsonrpc.new_request('nonexistent.method', '{}')
	nonexistent_json := nonexistent_request.encode()

	conn.write_string(nonexistent_json)!

	// Read method not found response
	bytes_read3 := conn.read(mut buffer)!
	method_error_data := buffer[..bytes_read3].bytestr()

	method_error_response := jsonrpc.decode_response(method_error_data)!
	assert method_error_response.is_error()
	assert method_error_response.id == nonexistent_request.id

	if error_obj := method_error_response.error() {
		assert error_obj.code == jsonrpc.method_not_found.code
	}
}
