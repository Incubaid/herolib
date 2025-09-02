#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heromodels.openrpc
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.ui.console
import time
import os

console.print_header('HeroModels OpenRPC Server Example')

// Create and start the server
mut server := openrpc.new_rpc_server(socket_path: '/tmp/heromodels')!

// Start server in a separate thread
spawn server.start()

console.print_item('Server started on /tmp/heromodels')
console.print_item('Press Ctrl+C to stop the server')

// Keep the main thread alive
for {
	time.sleep(1 * time.second)
}