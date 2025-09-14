#!/usr/bin/env vshell

// HeroFS RPC Example
// This example demonstrates how to start the HeroFS RPC server

import freeflowuniverse.herolib.hero.herofs.rpc { ServerArgs, start }

fn main() {
	// Example 1: Start RPC server with Unix socket
	println('Starting HeroFS RPC server with Unix socket...')
	mut args := ServerArgs{
		socket_path: '/tmp/herofs'
		http_port: 0 // No HTTP server
	}
	start(args)!
	println('HeroFS RPC server started successfully on Unix socket: ${args.socket_path}')

	// Example 2: Start RPC server with HTTP
	println('\nStarting HeroFS RPC server with HTTP on port 8080...')
	args = ServerArgs{
		socket_path: '/tmp/herofs'
		http_port: 8080
	}
	start(args)!
	println('HeroFS RPC server started successfully on HTTP port: ${args.http_port}')
}
