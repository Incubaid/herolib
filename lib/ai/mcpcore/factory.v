module mcp

import time
import os
import log
import x.json2
import freeflowuniverse.herolib.schemas.jsonrpc

@[params]
pub struct ServerParams {
pub:
	handlers map[string]jsonrpc.ProcedureHandler
	config   ServerConfiguration
}

// new_server creates a new MCP server
pub fn new_server(backend Backend, params ServerParams) !&Server {
	mut server := &Server{
		ServerConfiguration: params.config
		backend:             backend
	}

	// Create a handler with the core MCP procedures registered
	handler := jsonrpc.new_handler(jsonrpc.Handler{
		procedures: {
			//...params.handlers,
			// Core handlers
			'initialize':                server.initialize_handler
			'notifications/initialized': initialized_notification_handler
			// Resource handlers
			'resources/list':            server.resources_list_handler
			'resources/read':            server.resources_read_handler
			'resources/templates/list':  server.resources_templates_list_handler
			'resources/subscribe':       server.resources_subscribe_handler
			// Prompt handlers
			'prompts/list':              server.prompts_list_handler
			'prompts/get':               server.prompts_get_handler
			'completion/complete':       server.prompts_get_handler
			// Tool handlers
			'tools/list':                server.tools_list_handler
			'tools/call':                server.tools_call_handler
			// Sampling handlers
			'sampling/createMessage':    server.sampling_create_message_handler
		}
	})!

	server.handler = *handler
	return server
}
