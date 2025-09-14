module mcpgen

import freeflowuniverse.herolib.mcp.logger
import freeflowuniverse.herolib.mcp

@[heap]
pub struct MCPGen {}

pub fn new_mcp_server(v &MCPGen) !&mcp.Server {
	logger.info('Creating new Developer MCP server')

	// Initialize the server with the empty handlers map
	mut server := mcp.new_server(mcp.MemoryBackend{
		tools:         {
			'create_mcp_tool_code':    create_mcp_tool_code_tool
			'create_mcp_tool_const':   create_mcp_tool_const_tool
			'create_mcp_tool_handler': create_mcp_tool_handler_tool
			'create_mcp_tools_code':   create_mcp_tools_code_tool
		}
		tool_handlers: {
			'create_mcp_tool_code':    v.create_mcp_tool_code_tool_handler
			'create_mcp_tool_const':   v.create_mcp_tool_const_tool_handler
			'create_mcp_tool_handler': v.create_mcp_tool_handler_tool_handler
			'create_mcp_tools_code':   v.create_mcp_tools_code_tool_handler
		}
	}, mcp.ServerParams{
		config: mcp.ServerConfiguration{
			server_info: mcp.ServerInfo{
				name:    'mcpgen'
				version: '1.0.0'
			}
		}
	})!
	return server
}
