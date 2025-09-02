#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import net.unix
import x.json2
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.hero.heromodels.openrpc

// Example client to test the HeroModels OpenRPC server
fn main() {
	console.print_header('HeroModels OpenRPC Client Example')
	
	// Connect to the server
	mut conn := unix.connect_stream('/tmp/heromodels')!
	defer {
		conn.close() or {}
	}
	
	console.print_item('Connected to server')
	
	// Test 1: Get OpenRPC specification
	console.print_header('Test 1: Discover OpenRPC Specification')
	discover_request := openrpc.JsonRpcRequest{
		jsonrpc: '2.0'
		method: 'discover'
		params: json2.null
		id: json2.Any(1)
	}
	
	send_request(mut conn, discover_request)!
	response := read_response(mut conn)!
	console.print_item('OpenRPC Spec received: ${response.len} characters')
	
	// Test 2: Create a comment
	console.print_header('Test 2: Create Comment')
	comment_json := '{"comment": "This is a test comment from OpenRPC client", "parent": 0, "author": 1}'
	
	create_request := openrpc.JsonRpcRequest{
		jsonrpc: '2.0'
		method: 'comment_set'
		params: json2.raw_decode(comment_json)!
		id: json2.Any(2)
	}
	
	send_request(mut conn, create_request)!
	create_response := read_response(mut conn)!
	console.print_item('Comment created: ${create_response}')
	
	// Test 3: List all comments
	console.print_header('Test 3: List All Comments')
	list_request := openrpc.JsonRpcRequest{
		jsonrpc: '2.0'
		method: 'comment_list'
		params: json2.null
		id: json2.Any(3)
	}
	
	send_request(mut conn, list_request)!
	list_response := read_response(mut conn)!
	console.print_item('Comment list: ${list_response}')
	
	// Test 4: Get comment by author
	console.print_header('Test 4: Get Comments by Author')
	get_args_json := '{"author": 1}'
	
	get_request := openrpc.JsonRpcRequest{
		jsonrpc: '2.0'
		method: 'comment_get'
		params: json2.raw_decode(get_args_json)!
		id: json2.Any(4)
	}
	
	send_request(mut conn, get_request)!
	get_response := read_response(mut conn)!
	console.print_item('Comments by author: ${get_response}')
	
	console.print_header('All tests completed successfully!')
}

fn send_request(mut conn unix.StreamConn, request openrpc.JsonRpcRequest) ! {
	request_json := json2.encode(request)
	conn.write_string(request_json)!
}

fn read_response(mut conn unix.StreamConn) !string {
	mut buffer := []u8{len: 8192}
	bytes_read := conn.read(mut buffer)!
	return buffer[..bytes_read].bytestr()
}