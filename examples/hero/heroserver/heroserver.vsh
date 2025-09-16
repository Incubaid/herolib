#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heroserver
import freeflowuniverse.herolib.schemas.openrpc
import os

mut server := heroserver.new_server(heroserver.ServerConfig{
	port:        8080
	auth_config: heroserver.AuthConfig{}
})!

// Register the comments API with documentation
script_dir := os.dir(@FILE)
openrpc_path := os.join_path(script_dir, 'openrpc.json')
spec := openrpc.new(path: openrpc_path)!
handler := openrpc.new_handler(openrpc_path)!
server.register_api('comments', spec, handler)

// Setup documentation site
server.setup_docs_site() or { println('Warning: Failed to setup documentation site: ${err}') }

println('Server starting on http://localhost:8080')
println('Documentation available at: http://localhost:8080/docs')
println('Comments API available at: http://localhost:8080/api/comments')

server.start()!
