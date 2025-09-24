module main

import freeflowuniverse.herolib.mcp.v_do

fn main() {
	// Create and start the MCP server
	mut server := v_do.new_server()
	server.start() or {
		eprintln('Error starting server: ${err}')
		exit(1)
	}
}
