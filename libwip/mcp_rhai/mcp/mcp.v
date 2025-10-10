module mcp

import freeflowuniverse.herolib.ai.mcp
import freeflowuniverse.herolib.schemas.jsonrpc
import log

pub fn new_mcp_server() !&mcp.Server {
	log.info('Creating new Developer MCP server')

	// Initialize the server with the empty handlers map
	mut server := mcp.new_server(mcp.MemoryBackend{
		tools:           {
			'generate_rhai_wrapper': generate_rhai_wrapper_spec
		}
		tool_handlers:   {
			'generate_rhai_wrapper': generate_rhai_wrapper_handler
		}
		prompts:         {
			'rhai_wrapper': rhai_wrapper_prompt_spec
		}
		prompt_handlers: {
			'rhai_wrapper': rhai_wrapper_prompt_handler
		}
	}, mcp.ServerParams{
		config: mcp.ServerConfiguration{
			server_info: mcp.ServerInfo{
				name:    'rhai'
				version: '1.0.0'
			}
		}
	})!
	return server
}
