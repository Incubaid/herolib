module mcp

import incubaid.herolib.ai.mcpcore

// Re-export the main types from mcpcore
pub type Server = mcpcore.Server
pub type Backend = mcpcore.Backend
pub type MemoryBackend = mcpcore.MemoryBackend
pub type ServerConfiguration = mcpcore.ServerConfiguration
pub type ServerInfo = mcpcore.ServerInfo
pub type ServerParams = mcpcore.ServerParams
pub type Tool = mcpcore.Tool
pub type ToolContent = mcpcore.ToolContent
pub type ToolCallResult = mcpcore.ToolCallResult

// Re-export the main functions from mcpcore
pub fn new_server(backend Backend, params ServerParams) !&mcpcore.Server {
	return mcpcore.new_server(backend, params)
}

// Re-export helper functions from mcpcore
pub fn result_to_mcp_tool_contents[T](result T) []ToolContent {
	return mcpcore.result_to_mcp_tool_contents[T](result)
}

pub fn result_to_mcp_tool_content[T](result T) ToolContent {
	return mcpcore.result_to_mcp_tool_content[T](result)
}

// Note: LogLevel and SetLevelParams are already defined in handler_logging.v
