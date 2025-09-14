module mcp

import time
import os
import log
import x.json2
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
	log.info('Starting MCP server')
	for {
		// Read a message from stdin
		message := os.get_line()
		if message == '' {
			time.sleep(10000) // prevent cpu spinning
			continue
		}

		// Handle the message using the JSON-RPC handler
		response := s.handler.handle(message) or {
			log.error('message: ${message}')
			log.error('Error handling message: ${err}')

			// Try to extract the request ID
			id := jsonrpc.decode_request_id(message) or { 0 }

			// Create an internal error response
			error_response := jsonrpc.new_error(id, jsonrpc.internal_error).encode()
			print(error_response)
			continue
		}

		// Send the response only if it's not empty (notifications return empty responses)
		if response.len > 0 {
			s.send(response)
		}
	}
}

// send sends a response to the client
pub fn (mut s Server) send(response string) {
	// Send the response
	println(response)
	flush_stdout()
}
