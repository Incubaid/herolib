module mcp

import log
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.mcp.transport

// Server is the main MCP server struct
@[heap]
pub struct Server {
	ServerConfiguration
pub mut:
	client_config ClientConfiguration
	handler       jsonrpc.Handler
	backend       Backend
	transport     transport.Transport
}

// start starts the MCP server using the configured transport
pub fn (mut s Server) start() ! {
	// Note: Removed log.info() as it interferes with STDIO transport JSON-RPC communication
	s.transport.start(&s.handler)!
}

// send sends a response to the client using the configured transport
pub fn (mut s Server) send(response string) {
	s.transport.send(response)
}
