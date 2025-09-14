module mcpgen

import cli

pub const command = cli.Command{
	sort_flags: true
	name:       'mcpgen'
	// execute:     cmd_mcpgen
	description: 'will list existing mdbooks'
	commands:    [
		cli.Command{
			name:        'start'
			execute:     cmd_start
			description: 'start the MCP server'
		},
	]
}

fn cmd_start(cmd cli.Command) ! {
	mut server := new_mcp_server(&MCPGen{})!
	server.start()!
}
