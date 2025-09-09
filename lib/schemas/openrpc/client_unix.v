module openrpc

import x.json2 as json
import net.unix
import time
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.schemas.jsonrpc

pub struct UNIXClient {
pub mut:
	socket_path string
	timeout     int = 30 // Default timeout in seconds
}

@[params]
pub struct UNIXClientParams {
pub mut:
	socket_path string = '/tmp/heromodels'
	timeout     int    = 30
}

// new_unix_client creates a new OpenRPC Unix client
pub fn new_unix_client(params UNIXClientParams) &UNIXClient {
	return &UNIXClient{
		socket_path: params.socket_path
		timeout: params.timeout
	}
}

// call makes a JSON-RPC call to the server with typed parameters and result
pub fn (mut client UNIXClient) call_generic[T, D](method string, params T) !D {
	// Create a generic request with typed parameters
	response := client.call(method, json.encode(params))!
	return json.decode[D](response)
}

// call_str makes a JSON-RPC call with string parameters and returns string result
pub fn (mut client UNIXClient) call(method string, params string) !string {
	// Create a standard request with string parameters
	request := jsonrpc.new_request(method, params)

	// Send the request and get response
	response_json := client.send_request(request.encode())!

	// Decode response
	response := jsonrpc.decode_response(response_json) or {
		return error('Failed to decode response: ${err}')
	}
	
	// Validate response
	response.validate() or {
		return error('Invalid response: ${err}')
	}

	// Check ID matches
	if response.id != request.id {
		return error('Response ID ${response.id} does not match request ID ${request.id}')
	}

	// Return result or error
	return response.result()
}

// discover calls the rpc.discover method to get the OpenRPC specification
pub fn (mut client UNIXClient) discover() !OpenRPC {
	spec_json := client.call('rpc.discover', '')!
	return decode(spec_json)!
}

// send_request_str sends a string request and returns string result
fn (mut client UNIXClient) send_request(request string) !string {
	// Connect to Unix socket
	mut conn := unix.connect_stream(client.socket_path) or {
		return error('Failed to connect to Unix socket at ${client.socket_path}: ${err}')
	}
	
	defer {
		conn.close() or { console.print_stderr('Error closing connection: ${err}') }
	}
	
	// Set timeout
	if client.timeout > 0 {
		conn.set_read_timeout(client.timeout * time.second)
		conn.set_write_timeout(client.timeout * time.second)
	}
	
	// Send request
	console.print_debug('Sending request: ${request}')
	
	conn.write_string(request) or {
		return error('Failed to send request: ${err}')
	}
	
	// Read response
	mut buffer := []u8{len: 4096}
	bytes_read := conn.read(mut buffer) or {
		return error('Failed to read response: ${err}')
	}
	
	if bytes_read == 0 {
		return error('No response received from server')
	}
	
	response := buffer[..bytes_read].bytestr()
	console.print_debug('Received response: ${response}')
	
	return response
}

// ping sends a simple ping to test connectivity
pub fn (mut client UNIXClient) ping() !bool {
	// Try to discover the specification as a connectivity test
	client.discover() or {
		return error('Ping failed: ${err}')
	}
	return true
}

// close closes any persistent connections (currently no-op for Unix sockets)
pub fn (mut client UNIXClient) close() ! {
	// Unix socket connections are closed per request, so nothing to do here
}
