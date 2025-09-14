#!/usr/bin/env -S v -n -cg -w -parallel-cc -enable-globals run

import os
import flag

mut fp := flag.new_flag_parser(os.args)
fp.application('compile.vsh')
fp.version('v0.1.0')
fp.description('Compile MCP binary in debug or production mode')
fp.skip_executable()

prod_mode := fp.bool('prod', `p`, false, 'Build production version (optimized)')
help_requested := fp.bool('help', `h`, false, 'Show help message')

if help_requested {
	println(fp.usage())
	exit(0)
}

additional_args := fp.finalize() or {
	eprintln(err)
	println(fp.usage())
	exit(1)
}

if additional_args.len > 0 {
	eprintln('Unexpected arguments: ${additional_args.join(' ')}')
	println(fp.usage())
	exit(1)
}

// Change to the mcp directory
mcp_dir := os.dir(os.real_path(os.executable()))
os.chdir(mcp_dir) or { panic('Failed to change directory to ${mcp_dir}: ${err}') }

// Set MCPPATH based on OS
mut mcppath := '/usr/local/bin/mcp'
if os.user_os() == 'macos' {
	mcppath = os.join_path(os.home_dir(), 'hero/bin/mcp')
}

// Set compilation command based on OS and mode
compile_cmd := if prod_mode {
	'v -enable-globals -w -n -prod mcp.v'
} else {
	'v -w -cg -gc none -cc tcc -d use_openssl -enable-globals mcp.v'
}

println('Building MCP in ${if prod_mode { 'production' } else { 'debug' }} mode...')

if os.system(compile_cmd) != 0 {
	panic('Failed to compile mcp.v with command: ${compile_cmd}')
}

// Make executable
os.chmod('mcp', 0o755) or { panic('Failed to make mcp binary executable: ${err}') }

// Ensure destination directory exists
os.mkdir_all(os.dir(mcppath)) or { panic('Failed to create directory ${os.dir(mcppath)}: ${err}') }

// Copy to destination paths
os.cp('mcp', mcppath) or { panic('Failed to copy mcp binary to ${mcppath}: ${err}') }
os.cp('mcp', '/tmp/mcp') or { panic('Failed to copy mcp binary to /tmp/mcp: ${err}') }

// Clean up
os.rm('mcp') or { panic('Failed to remove temporary mcp binary: ${err}') }

println('**MCP COMPILE OK**')
