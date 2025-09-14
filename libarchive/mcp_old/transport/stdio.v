module transport

import time
import os
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.schemas.jsonrpc

// StdioTransport implements the Transport interface for standard input/output communication.
// This is the original MCP transport method where the server reads JSON-RPC requests from stdin
// and writes responses to stdout. This transport is used for process-to-process communication.
pub struct StdioTransport {
mut:
	handler &jsonrpc.Handler = unsafe { nil }
}

// new_stdio_transport creates a new STDIO transport instance
pub fn new_stdio_transport() Transport {
	return &StdioTransport{}
}

// start implements the Transport interface for STDIO communication.
// It reads JSON-RPC messages from stdin, processes them with the handler,
// and sends responses to stdout.
pub fn (mut t StdioTransport) start(handler &jsonrpc.Handler) ! {
	unsafe {
		t.handler = handler
	}
	// Note: In STDIO mode, we should not print any debug messages to stdout
	// as it interferes with JSON-RPC communication

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
		response := t.handler.handle(request) or {
			// Note: Removed stderr logging as it can interfere with MCP Inspector

			// Create an internal error response
			error_response := jsonrpc.new_error(request.id, jsonrpc.internal_error).encode()
			println(error_response)
			continue
		}

		// Send the response (notifications may return empty responses)
		response_str := response.encode()
		if response_str.len > 0 {
			t.send(response_str)
		}
	}
}

// send implements the Transport interface for STDIO communication.
// It writes the response to stdout and flushes the output buffer.
pub fn (mut t StdioTransport) send(response string) {
	println(response)
	flush_stdout()
}
