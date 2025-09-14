module mcp

import x.json2
import freeflowuniverse.herolib.schemas.jsonrpc

// LogLevel represents the logging levels supported by MCP
pub enum LogLevel {
	debug
	info
	notice
	warning
	error
	critical
	alert
	emergency
}

// SetLevelParams represents the parameters for the logging/setLevel method
pub struct SetLevelParams {
pub:
	level LogLevel
}

// logging_set_level_handler handles the logging/setLevel request
// This is a stub implementation that accepts the request but doesn't actually change logging behavior
fn (mut s Server) logging_set_level_handler(data string) !string {
	// Decode the request with SetLevelParams
	request := jsonrpc.decode_request_generic[SetLevelParams](data)!

	// For now, we just acknowledge the request without actually implementing logging level changes
	// In a full implementation, this would configure the server's logging system

	// Create a success response with empty object (logging/setLevel returns {} on success)
	empty_map := map[string]string{}
	response := jsonrpc.new_response_generic[map[string]string](request.id, empty_map)
	return response.encode()
}
