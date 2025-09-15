module mcp

import time
import os
import freeflowuniverse.herolib.schemas.jsonrpc

// Server is the main MCP server struct
@[heap]
pub struct Server {
	ServerConfiguration
pub mut:
	client_config ClientConfiguration
	handler       jsonrpc.Handler
	backend       Backend
}

// start starts the MCP server
pub fn (mut s Server) start() ! {
	// Note: Removed log.info() as it interferes with STDIO transport JSON-RPC communication
	for {
		// Read a message from stdin
		message := os.get_line()
		if message == '' {
			time.sleep(10000) // prevent cpu spinning
			continue
		}

		// Parse the JSON-RPC request
		request := jsonrpc.decode_request(message) or {
			// Note: Removed stderr logging as it can interfere with MCP Inspector
			// Try to extract the request ID for error response
			id := jsonrpc.decode_request_id(message) or { 0 }
			// Create an invalid request error response
			error_response := jsonrpc.new_error(id, jsonrpc.invalid_request).encode()
			println(error_response)
			continue
		}

		// Handle the message using the JSON-RPC handler
		response := s.handler.handle(request) or {
			// Note: Removed stderr logging as it can interfere with MCP Inspector

			// Create an internal error response
			error_response := jsonrpc.new_error(request.id, jsonrpc.internal_error).encode()
			println(error_response)
			continue
		}

		// Send the response (notifications may return empty responses)
		response_str := response.encode()
		if response_str.len > 0 {
			s.send(response_str)
		}
	}
}

// send sends a response to the client
pub fn (mut s Server) send(response string) {
	// Send the response
	println(response)
	flush_stdout()
}
