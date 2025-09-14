module mcp

import time
import os
import log
import x.json2
import freeflowuniverse.herolib.schemas.jsonrpc

const protocol_version = '2024-11-05'
// MCP server implementation using stdio transport
// Based on https://modelcontextprotocol.io/docs/concepts/transports

// ClientConfiguration represents the parameters for the initialize request
pub struct ClientConfiguration {
pub:
	protocol_version string @[json: 'protocolVersion']
	capabilities     ClientCapabilities
	client_info      ClientInfo @[json: 'clientInfo']
}

// ClientCapabilities represents the client capabilities
pub struct ClientCapabilities {
pub:
	roots        RootsCapability        // Ability to provide filesystem roots
	sampling     SamplingCapability     // Support for LLM sampling requests
	experimental ExperimentalCapability // Describes support for non-standard experimental features
}

// RootsCapability represents the roots capability
pub struct RootsCapability {
pub:
	list_changed bool @[json: 'listChanged']
}

// SamplingCapability represents the sampling capability
pub struct SamplingCapability {}

// ExperimentalCapability represents the experimental capability
pub struct ExperimentalCapability {}

// ClientInfo represents the client information
pub struct ClientInfo {
pub:
	name    string
	version string
}

// ServerConfiguration represents the server configuration
pub struct ServerConfiguration {
pub:
	protocol_version string = '2024-11-05' @[json: 'protocolVersion']
	capabilities     ServerCapabilities
	server_info      ServerInfo @[json: 'serverInfo']
}

// ServerCapabilities represents the server capabilities
pub struct ServerCapabilities {
pub:
	logging   LoggingCapability
	prompts   PromptsCapability
	resources ResourcesCapability
	tools     ToolsCapability
}

// LoggingCapability represents the logging capability
pub struct LoggingCapability {
}

// PromptsCapability represents the prompts capability
pub struct PromptsCapability {
pub:
	list_changed bool = true @[json: 'listChanged']
}

// ResourcesCapability represents the resources capability
pub struct ResourcesCapability {
pub:
	subscribe    bool = true @[json: 'subscribe']
	list_changed bool = true @[json: 'listChanged']
}

// ToolsCapability represents the tools capability
pub struct ToolsCapability {
pub:
	list_changed bool = true @[json: 'listChanged']
}

// ServerInfo represents the server information
pub struct ServerInfo {
pub:
	name    string = 'HeroLibMCPServer'
	version string = '1.0.0'
}
