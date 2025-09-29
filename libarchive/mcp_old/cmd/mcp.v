module main

import os
import cli { Command, Flag }
import freeflowuniverse.herolib.osal.core as osal
// import freeflowuniverse.herolib.mcp.vcode
// import freeflowuniverse.herolib.mcp.mcpgen
// import freeflowuniverse.herolib.mcp.baobab
import freeflowuniverse.herolib.mcp.rhai.mcp as rhai_mcp

fn main() {
	do() or { panic(err) }
}

pub fn do() ! {
	mut cmd_mcp := Command{
		name:          'mcp'
		usage:         '
## Manage your MCPs

example:

mcp
		'
		description:   'create, edit, show mdbooks'
		required_args: 0
	}

	// cmd_run_add_flags(mut cmd_publisher)

	cmd_mcp.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'debug'
		abbrev:      'd'
		description: 'show debug output'
	})

	cmd_mcp.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'verbose'
		abbrev:      'v'
		description: 'show verbose output'
	})

	mut cmd_inspector := Command{
		sort_flags:  true
		name:        'inspector'
		execute:     cmd_inspector_execute
		description: 'will list existing mdbooks'
	}

	cmd_inspector.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'name'
		abbrev:      'n'
		description: 'name of the MCP'
	})

	cmd_inspector.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'open'
		abbrev:      'o'
		description: 'open inspector'
	})

	cmd_mcp.add_command(rhai_mcp.command)
	// cmd_mcp.add_command(baobab.command)
	// cmd_mcp.add_command(vcode.command)
	cmd_mcp.add_command(cmd_inspector)
	// cmd_mcp.add_command(vcode.command)
	cmd_mcp.setup()
	cmd_mcp.parse(os.args)
}

fn cmd_inspector_execute(cmd Command) ! {
	open := cmd.flags.get_bool('open') or { false }
	if open {
		osal.exec(cmd: 'open http://localhost:5173')!
	}
	name := cmd.flags.get_string('name') or { '' }
	if name.len > 0 {
		println('starting inspector for MCP ${name}')
		osal.exec(cmd: 'npx @modelcontextprotocol/inspector mcp ${name} start')!
	} else {
		osal.exec(cmd: 'npx @modelcontextprotocol/inspector')!
	}
}
