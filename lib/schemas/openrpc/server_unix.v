module openrpc

import net.unix
import os
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.schemas.jsonrpc

pub struct UNIXServer {
pub mut:
	listener    &unix.StreamListener
	socket_path string
	handler     Handler @[required]
}

@[params]
pub struct UNIXServerParams {
pub mut:
	socket_path string = '/tmp/heromodels'
}

pub fn start_unix_server(handler Handler, params UNIXServerParams) ! {
	mut server := new_unix_server(handler, params)!
	server.start()!
}

pub fn new_unix_server(handler Handler, params UNIXServerParams) !&UNIXServer {
	// Remove existing socket file if it exists
	if os.exists(params.socket_path) {
		os.rm(params.socket_path)!
	}

	listener := unix.listen_stream(params.socket_path, unix.ListenOptions{})!

	return &UNIXServer{
		listener:    listener
		handler:     handler
		socket_path: params.socket_path
	}
}

pub fn (mut server UNIXServer) start() ! {
	console.print_header('Starting HeroModels OpenRPC Server on ${server.socket_path}')

	for {
		mut conn := server.listener.accept()!
		spawn server.handle_connection(mut conn)
	}
}

pub fn (mut server UNIXServer) close() ! {
	server.listener.close()!
	if os.exists(server.socket_path) {
		os.rm(server.socket_path)!
	}
}

fn (mut server UNIXServer) handle_connection(mut conn unix.StreamConn) {
	defer {
		conn.close() or { console.print_stderr('Error closing connection: ${err}') }
	}

	for {
		// Read JSON-RPC request
		mut buffer := []u8{len: 4096}
		bytes_read := conn.read(mut buffer) or {
			console.print_debug('Connection closed or error reading: ${err}')
			break
		}

		if bytes_read == 0 {
			break
		}

		request_data := buffer[..bytes_read].bytestr()
		console.print_debug('Received request: ${request_data}')

		// Process the JSON-RPC request
		if response := server.process_request(request_data) {
			// Send response only if we have a valid response
			conn.write_string(response) or {
				console.print_stderr('Error writing response: ${err}')
				break
			}
		} else {
			// Log the error but don't break the connection
			// According to JSON-RPC 2.0 spec, if we can't decode the request ID,
			// we should not send any response but keep the connection alive
			console.print_debug('Invalid request received, no response sent: ${err}')
		}
	}
}

fn (mut server UNIXServer) process_request(request_data string) ?string {
	// Parse JSON-RPC request using json2 to handle Any types
	request := jsonrpc.decode_request(request_data) or {
		// try decoding id to give error response
		if id := jsonrpc.decode_request_id(request_data) {
			// We can extract ID, so return proper JSON-RPC error response
			return jsonrpc.new_error(id, jsonrpc.invalid_request).encode()
		} else {
			// Cannot extract ID from invalid JSON - return none (no response)
			// This follows JSON-RPC 2.0 spec: no response when ID cannot be determined
			return none
		}
	}
	response := server.handler.handle(request) or {
		return jsonrpc.new_error(request.id, jsonrpc.internal_error).encode()
	}
	return response.encode()
}
