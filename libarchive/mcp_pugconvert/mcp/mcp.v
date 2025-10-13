module mcp

import incubaid.herolib.ai.mcp
import incubaid.herolib.ai.mcp.logger
import incubaid.herolib.schemas.jsonrpc

pub fn new_mcp_server() !&Server {
	logger.info('Creating new Developer MCP server')

	// Initialize the server with the empty handlers map
	mut server := mcp.new_server(MemoryBackend{
		tools:         {
			'pugconvert': specs
		}
		tool_handlers: {
			'pugconvert': handler
		}
	}, ServerParams{
		config: ServerConfiguration{
			server_info: ServerInfo{
				name:    'developer'
				version: '1.0.0'
			}
		}
	})!
	return server
}
