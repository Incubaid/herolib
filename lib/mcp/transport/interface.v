module transport

import freeflowuniverse.herolib.schemas.jsonrpc

// Transport defines the interface for different MCP transport mechanisms.
// This abstraction allows MCP servers to work with multiple transport protocols
// (STDIO, HTTP, WebSocket, etc.) without changing the core MCP logic.
pub interface Transport {
mut:
	// start begins listening for requests and handling them with the provided JSON-RPC handler.
	// This method should block and run the transport's main loop.
	//
	// Parameters:
	//   - handler: The JSON-RPC handler that processes MCP protocol messages
	//
	// Returns:
	//   - An error if the transport fails to start or encounters a fatal error
	start(handler &jsonrpc.Handler) !

	// send transmits a response back to the client.
	// The implementation depends on the transport type (stdout for STDIO, HTTP response, etc.)
	//
	// Parameters:
	//   - response: The JSON-RPC response string to send to the client
	send(response string)
}

// TransportMode defines the available transport types
pub enum TransportMode {
	stdio // Standard input/output transport (current default)
	http  // HTTP/REST transport (new)
}

// TransportConfig holds configuration for different transport types
pub struct TransportConfig {
pub:
	mode TransportMode = .stdio
	http HttpConfig
}

// HttpConfig holds HTTP-specific configuration
pub struct HttpConfig {
pub:
	port     int      = 8080        // Port to listen on
	host     string   = 'localhost' // Host to bind to
	protocol HttpMode = .both       // Which HTTP protocols to support
}

// HttpMode defines which HTTP protocols the server should support
pub enum HttpMode {
	jsonrpc_only // Only JSON-RPC over HTTP endpoint
	rest_only    // Only REST API endpoints
	both         // Both JSON-RPC and REST endpoints
}
