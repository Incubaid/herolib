module mcp

import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.mcp.transport

// Wrapper functions to convert string-based handlers to jsonrpc.Request/Response format
// We reconstruct the original JSON to avoid double-encoding issues

fn create_initialize_wrapper(mut server Server) jsonrpc.ProcedureHandler {
	return fn [mut server] (request jsonrpc.Request) !jsonrpc.Response {
		// Reconstruct the original JSON from the request object
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := server.initialize_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

fn create_initialized_notification_wrapper() jsonrpc.ProcedureHandler {
	return fn (request jsonrpc.Request) !jsonrpc.Response {
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := initialized_notification_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

fn create_resources_list_wrapper(mut server Server) jsonrpc.ProcedureHandler {
	return fn [mut server] (request jsonrpc.Request) !jsonrpc.Response {
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := server.resources_list_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

fn create_resources_read_wrapper(mut server Server) jsonrpc.ProcedureHandler {
	return fn [mut server] (request jsonrpc.Request) !jsonrpc.Response {
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := server.resources_read_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

fn create_resources_templates_list_wrapper(mut server Server) jsonrpc.ProcedureHandler {
	return fn [mut server] (request jsonrpc.Request) !jsonrpc.Response {
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := server.resources_templates_list_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

fn create_resources_subscribe_wrapper(mut server Server) jsonrpc.ProcedureHandler {
	return fn [mut server] (request jsonrpc.Request) !jsonrpc.Response {
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := server.resources_subscribe_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

fn create_prompts_list_wrapper(mut server Server) jsonrpc.ProcedureHandler {
	return fn [mut server] (request jsonrpc.Request) !jsonrpc.Response {
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := server.prompts_list_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

fn create_prompts_get_wrapper(mut server Server) jsonrpc.ProcedureHandler {
	return fn [mut server] (request jsonrpc.Request) !jsonrpc.Response {
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := server.prompts_get_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

fn create_tools_list_wrapper(mut server Server) jsonrpc.ProcedureHandler {
	return fn [mut server] (request jsonrpc.Request) !jsonrpc.Response {
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := server.tools_list_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

fn create_tools_call_wrapper(mut server Server) jsonrpc.ProcedureHandler {
	return fn [mut server] (request jsonrpc.Request) !jsonrpc.Response {
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := server.tools_call_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

fn create_logging_set_level_wrapper(mut server Server) jsonrpc.ProcedureHandler {
	return fn [mut server] (request jsonrpc.Request) !jsonrpc.Response {
		original_json := '{"jsonrpc":"${request.jsonrpc}","method":"${request.method}","params":${request.params},"id":${request.id}}'
		response_str := server.logging_set_level_handler(original_json)!
		return jsonrpc.decode_response(response_str)!
	}
}

@[params]
pub struct ServerParams {
pub:
	handlers  map[string]jsonrpc.ProcedureHandler
	config    ServerConfiguration
	transport transport.TransportConfig = transport.TransportConfig{
		mode: .stdio
	}
}

// new_server creates a new MCP server
pub fn new_server(backend Backend, params ServerParams) !&Server {
	// Create the appropriate transport based on configuration
	transport_impl := match params.transport.mode {
		.stdio {
			transport.new_stdio_transport()
		}
		.http {
			transport.new_http_transport(params.transport.http)
		}
	}

	mut server := &Server{
		ServerConfiguration: params.config
		backend:             backend
		transport:           transport_impl
	}

	// Create a handler with the core MCP procedures registered
	handler := jsonrpc.new_handler(jsonrpc.Handler{
		procedures: {
			// ...params.handlers,
			// Core handlers
			'initialize':                create_initialize_wrapper(mut server)
			'notifications/initialized': create_initialized_notification_wrapper()
			// Logging handlers
			'logging/setLevel':          create_logging_set_level_wrapper(mut server)
			// Resource handlers
			'resources/list':            create_resources_list_wrapper(mut server)
			'resources/read':            create_resources_read_wrapper(mut server)
			'resources/templates/list':  create_resources_templates_list_wrapper(mut server)
			'resources/subscribe':       create_resources_subscribe_wrapper(mut server)
			// Prompt handlers
			'prompts/list':              create_prompts_list_wrapper(mut server)
			'prompts/get':               create_prompts_get_wrapper(mut server)
			'completion/complete':       create_prompts_get_wrapper(mut server)
			// Tool handlers
			'tools/list':                create_tools_list_wrapper(mut server)
			'tools/call':                create_tools_call_wrapper(mut server)
		}
	})!

	server.handler = *handler
	return server
}
