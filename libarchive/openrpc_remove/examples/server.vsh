#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.core.jobs.openrpc
import freeflowuniverse.herolib.core.jobs.model
import time
import sync
import os

fn start_rpc_server(mut wg sync.WaitGroup) ! {
	defer { wg.done() }

	// Create OpenRPC server
	openrpc.server_start()!
}

fn start_ws_server(mut wg sync.WaitGroup) ! {
	defer { wg.done() }

	// Get port from environment variable or use default
	port := if ws_port := os.getenv_opt('WS_PORT') {
		ws_port.int()
	} else {
		8080
	}

	// Create and start WebSocket server
	mut ws_server := openrpc.new_ws_server(port)!
	ws_server.start()!
}

// Create wait group for servers
mut wg := sync.new_waitgroup()
wg.add(2)

// Start servers in separate threads
spawn start_rpc_server(mut wg)
spawn start_ws_server(mut wg)

// Wait for servers to finish (they run forever)
wg.wait()
