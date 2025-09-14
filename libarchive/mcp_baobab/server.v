module baobab

import freeflowuniverse.herolib.ai.mcp
import freeflowuniverse.herolib.ai.mcp.logger
import freeflowuniverse.herolib.schemas.jsonrpc

@[heap]
pub struct Baobab {}

pub fn new_mcp_server(v &Baobab) !&mcp.Server {
	logger.info('Creating new Baobab MCP server')

	// Initialize the server with the empty handlers map
	mut server := mcp.new_server(mcp.MemoryBackend{
		tools:         {
			'generate_module_from_openapi':    generate_module_from_openapi_tool
			'generate_methods_file':           generate_methods_file_tool
			'generate_methods_interface_file': generate_methods_interface_file_tool
			'generate_model_file':             generate_model_file_tool
			'generate_methods_example_file':   generate_methods_example_file_tool
		}
		tool_handlers: {
			'generate_module_from_openapi':    v.generate_module_from_openapi_tool_handler
			'generate_methods_file':           v.generate_methods_file_tool_handler
			'generate_methods_interface_file': v.generate_methods_interface_file_tool_handler
			'generate_model_file':             v.generate_model_file_tool_handler
			'generate_methods_example_file':   v.generate_methods_example_file_tool_handler
		}
	}, mcp.ServerParams{
		config: mcp.ServerConfiguration{
			server_info: mcp.ServerInfo{
				name:    'baobab'
				version: '1.0.0'
			}
		}
	})!
	return server
}
