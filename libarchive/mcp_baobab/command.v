module baobab

import cli

pub const command = cli.Command{
	sort_flags: true
	name:       'baobab'
	// execute:     cmd_mcpgen
	description: 'baobab command'
	commands:    [
		cli.Command{
			name:        'start'
			execute:     cmd_start
			description: 'start the Baobab server'
		},
	]
}

fn cmd_start(cmd cli.Command) ! {
	mut server := new_mcp_server(&Baobab{})!
	server.start()!
}
