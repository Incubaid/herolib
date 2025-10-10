module mcp

import time
import os
import log
import x.json2
import freeflowuniverse.herolib.schemas.jsonrpc

// initialize_handler handles the initialize request according to the MCP specification
fn (mut s Server) initialize_handler(data string) !string {
	// Decode the request with ClientConfiguration parameters
	request := jsonrpc.decode_request_generic[ClientConfiguration](data)!
	s.client_config = request.params

	// Create a success response with the result
	response := jsonrpc.new_response_generic[ServerConfiguration](request.id, s.ServerConfiguration)
	return response.encode()
}

// initialized_notification_handler handles the initialized notification
// This notification is sent by the client after successful initialization
fn initialized_notification_handler(data string) !string {
	// This is a notification, so no response is expected
	// Just log that we received the notification
	log.info('Received initialized notification')
	return ''
}
