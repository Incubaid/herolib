module openrpc

import json
import x.json2
import net.unix
import os
import freeflowuniverse.herolib.ui.console

//THIS IS DEFAULT NEEDED FOR EACH OPENRPC SERVER WE MAKE

pub struct JsonRpcRequest {
pub:
	jsonrpc string = '2.0'
	method  string
	params  string
	id      string
}

// JSON-RPC 2.0 response structure
pub struct JsonRpcResponse {
pub:
	jsonrpc string = '2.0'
	result  string
	error   ?JsonRpcError
	id      string
}

// JSON-RPC 2.0 error structure
pub struct JsonRpcError {
pub:
	code    int
	message string
	data    string
}


pub struct RPCServer {
pub mut:
	listener &unix.StreamListener
	socket_path string
}

@[params]
pub struct RPCServerArgs {
pub mut:
	socket_path string = '/tmp/heromodels'
}

// Temporary struct for parsing incoming JSON-RPC requests using json2
struct JsonRpcRequestRaw {
	jsonrpc string
	method  string
	params  json2.Any
	id      json2.Any
}

pub fn new_rpc_server(args RPCServerArgs) !&RPCServer {
	// Remove existing socket file if it exists
	if os.exists(args.socket_path) {
		os.rm(args.socket_path)!
	}
	
	listener := unix.listen_stream(args.socket_path, unix.ListenOptions{})!
	
	return &RPCServer{
		listener: listener
		socket_path: args.socket_path
	}
}

pub fn (mut server RPCServer) start() ! {
	console.print_header('Starting HeroModels OpenRPC Server on ${server.socket_path}')
	
	for {
		mut conn := server.listener.accept()!
		spawn server.handle_connection(mut conn)
	}
}

pub fn (mut server RPCServer) close() ! {
	server.listener.close()!
	if os.exists(server.socket_path) {
		os.rm(server.socket_path)!
	}
}

fn (mut server RPCServer) handle_connection(mut conn unix.StreamConn) {
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
		response := server.process_request(request_data) or {
			server.create_error_response(-32603, 'Internal error: ${err}', 'null')
		}
		
		// Send response
		conn.write_string(response) or {
			console.print_stderr('Error writing response: ${err}')
			break
		}
	}
}

fn (mut server RPCServer) process_request(request_data string) !string {
	// Parse JSON-RPC request using json2 to handle Any types
	request := json2.decode[JsonRpcRequestRaw](request_data)!
	// Convert params to string representation
	params_str := request.params.json_str()
	// Convert id to string
	id_str := request.id.json_str()
	r := request.method.trim_space().to_lower()
	// Route to appropriate method
	result := server.process(r, params_str)!
	return server.create_success_response(result, id_str)
}

fn (mut server RPCServer) create_success_response(result string, id string) string {
	response := JsonRpcResponse{
		jsonrpc: '2.0'
		result: result
		id: id
	}
	return json.encode(response)
}

fn (mut server RPCServer) create_error_response(code int, message string, id string) string {
	error := JsonRpcError{
		code: code
		message: message
		data: 'null'
	}
	response := JsonRpcResponse{
		jsonrpc: '2.0'
		error: error
		id: id
	}
	return json.encode(response)
}

// discover returns the OpenRPC specification for the HeroModels service
fn (mut server RPCServer) discover() !string {
	spec_json := $tmpl("openrpc.json")
	return spec_json
}