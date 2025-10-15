module vcode

import incubaid.herolib.ai.mcp
import incubaid.herolib.ai.mcp.vcode.logic

pub fn new_mcp_server() !&mcp.Server {
	// Note: Removed logger.info() as it interferes with STDIO transport JSON-RPC communication

	// Create a VCode instance and delegate to the logic module
	v := &logic.VCode{}
	return logic.new_mcp_server(v)
}
