module main

import incubaid.herolib.ai.mcp.rhai.mcp

fn main() {
	// Create a new MCP server
	mut server := mcp.new_mcp_server() or {
		// Note: Removed log.error() as it interferes with STDIO transport JSON-RPC communication
		return
	}

	// Start the server
	server.start() or {
		// Note: Removed log.error() as it interferes with STDIO transport JSON-RPC communication
		return
	}
}
