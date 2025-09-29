module main

import freeflowuniverse.herolib.ai.mcp.servers.pugconvert.mcp

fn main() {
	// Create a new MCP server
	mut server := mcp.new_mcp_server() or {
		eprintln('Failed to create MCP server: ${err}')
		return
	}

	// Start the server
	server.start() or {
		eprintln('Failed to start MCP server: ${err}')
		return
	}
}
