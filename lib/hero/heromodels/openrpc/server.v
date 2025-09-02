module openrpc

import json
import x.json2 { Any }
import net.unix
import os
import freeflowuniverse.herolib.ui.console

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
	// Parse JSON-RPC request manually to handle params properly
	request_map := json.decode(map[string]Any, request_data)!
	
	jsonrpc := request_map['jsonrpc']!.str()
	method := request_map['method']!.str()
	id := request_map['id']!.str()
	
	// Handle params - convert to string representation
	params_str := if 'params' in request_map {
		params_any := request_map['params']!
		match params_any {
			string {
				params_any
			}
			else {
				json.encode(params_any)
			}
		}
	} else {
		'null'
	}
	
	// Route to appropriate method
	result := match method {
		'comment_get' {
			server.comment_get(params_str)!
		}
		'comment_set' {
			server.comment_set(params_str)!
		}
		'comment_delete' {
			server.comment_delete(params_str)!
		}
		'comment_list' {
			server.comment_list()!
		}
		'discover' {
			server.discover()!
		}
		else {
			return server.create_error_response(-32601, 'Method not found', id)
		}
	}
	
	return server.create_success_response(result, id)
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