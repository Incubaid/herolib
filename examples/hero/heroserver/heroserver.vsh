#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heroserver
import freeflowuniverse.herolib.schemas.openrpc
import os

// 1. Create a new server instance
mut server := heroserver.new(port: 8086)!

// 2. Create and register your OpenRPC handlers
//    These handlers must conform to the `openrpc.OpenRPCHandler` interface.
script_dir := os.dir(@FILE)
openrpc_path := os.join_path(script_dir, 'openrpc.json')
handler := openrpc.new_handler(openrpc_path)!
server.register_handler('comments', handler)!

println('Server starting on http://localhost:8086')
println('Documentation available at: http://localhost:8086/doc/comments/')
println('Comments API available at: http://localhost:8086/api/comments')

server.start()!
