module mcp

import cli

pub const command = cli.Command{
	sort_flags: true
	name:       'rhai'
	// execute:     cmd_mcpgen
	description: 'rhai command'
	commands:    [
		cli.Command{
			name:        'start'
			execute:     cmd_start
			description: 'start the Rhai server'
		},
	]
}

fn cmd_start(cmd cli.Command) ! {
	mut server := new_mcp_server()!
	server.start()!
}
