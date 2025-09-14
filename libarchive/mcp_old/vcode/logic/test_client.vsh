#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import os
import flag
import json

// Simple test client for the V-Do MCP server
// This script sends test requests to the MCP server and displays the responses

// struct MCPRequest {
// 	id      string
// 	method  string
// 	params  map[string]string
// 	jsonrpc string = '2.0'
// }

// fn send_request(method string, fullpath string) {
// 	// Create the request
// 	request := MCPRequest{
// 		id: '1'
// 		method: method
// 		params: {
// 			'fullpath': fullpath
// 		}
// 	}

// 	// Encode to JSON
// 	json_str := json.encode(request)

// 	// Format the message with headers
// 	message := 'Content-Length: ${json_str.len}\r\n\r\n${json_str}'

// 	// Write to a temporary file
// 	os.write_file('/tmp/mcp_request.txt', message) or {
// 		eprintln('Failed to write request to file: $err')
// 		return
// 	}

// 	// Execute the MCP server with the request
// 	cmd := 'cat /tmp/mcp_request.txt | v run /Users/despiegk/code/github/freeflowuniverse/herolib/lib/mcp/v_do/main.v'
// 	result := os.execute(cmd)

// 	if result.exit_code != 0 {
// 		eprintln('Error executing MCP server: ${result.output}')
// 		return
// 	}

// 	// Parse and display the response
// 	response := result.output
// 	println('Raw response:')
// 	println('-----------------------------------')
// 	println(response)
// 	println('-----------------------------------')

// 	// Try to extract the JSON part
// 	if response.contains('{') && response.contains('}') {
// 		json_start := response.index_after('{', 0)
// 		json_end := response.last_index_of('}')
// 		if json_start >= 0 && json_end >= 0 && json_end > json_start {
// 			json_part := response[json_start-1..json_end+1]
// 			println('Extracted JSON:')
// 			println(json_part)
// 		}
// 	}
// }

// // Parse command line arguments
// mut fp := flag.new_flag_parser(os.args)
// fp.application('test_client.vsh')
// fp.version('v0.1.0')
// fp.description('Test client for V-Do MCP server')
// fp.skip_executable()

// method := fp.string('method', `m`, 'test', 'Method to call (test, run, compile, vet)')
// fullpath := fp.string('path', `p`, '', 'Path to the file or directory to process')
// help_requested := fp.bool('help', `h`, false, 'Show help message')

// if help_requested {
// 	println(fp.usage())
// 	exit(0)
// }

// additional_args := fp.finalize() or {
// 	eprintln(err)
// 	println(fp.usage())
// 	exit(1)
// }

// if fullpath == '' {
// 	eprintln('Error: Path is required')
// 	println(fp.usage())
// 	exit(1)
// }

// // Validate method
// valid_methods := ['test', 'run', 'compile', 'vet']
// if method !in valid_methods {
// 	eprintln('Error: Invalid method. Must be one of: ${valid_methods}')
// 	println(fp.usage())
// 	exit(1)
// }

// // Send the request
// println('Sending $method request for $fullpath...')
// send_request(method, fullpath)
