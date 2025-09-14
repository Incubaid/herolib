module vcode

import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.mcp.logger

@[heap]
pub struct VCode {
	v_version string = '0.1.0'
}

pub fn new_mcp_server(v &VCode) !&mcp.Server {
	logger.info('Creating new Developer MCP server')

	// Initialize the server with the empty handlers map
	mut server := mcp.new_server(mcp.MemoryBackend{
		tools:         {
			'get_function_from_file': get_function_from_file_tool
			'write_vfile':            write_vfile_tool
		}
		tool_handlers: {
			'get_function_from_file': v.get_function_from_file_tool_handler
			'write_vfile':            v.write_vfile_tool_handler
		}
	}, mcp.ServerParams{
		config: mcp.ServerConfiguration{
			server_info: mcp.ServerInfo{
				name:    'vcode'
				version: '1.0.0'
			}
		}
	})!
	return server
}
