module main

import freeflowuniverse.herolib.ai.mcp.rhai.mcp
import log

fn main() {
	// Create a new MCP server
	mut server := mcp.new_mcp_server() or {
		log.error('Failed to create MCP server: ${err}')
		return
	}

	// Start the server
	server.start() or {
		log.error('Failed to start MCP server: ${err}')
		return
	}
}
