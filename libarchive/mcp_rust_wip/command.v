module rust

import cli

pub const command = cli.Command{
	sort_flags:  true
	name:        'rust'
	description: 'Rust language tools command'
	commands:    [
		cli.Command{
			name:        'start'
			execute:     cmd_start
			description: 'start the Rust MCP server'
		},
	]
}

fn cmd_start(cmd cli.Command) ! {
	mut server := new_mcp_server()!
	server.start()!
}
