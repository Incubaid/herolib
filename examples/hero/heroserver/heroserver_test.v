import freeflowuniverse.herolib.hero.heroserver
import freeflowuniverse.herolib.schemas.openrpc

fn testsuite_begin() {
	// a clean start
	// os.rm('./db')! //TODO: was giving issues
}

fn test_heroserver_new() {
	// Create server
	mut server := heroserver.new_server(port: 8080)!

	// Register handlers
	spec := openrpc.from_file('./openrpc.json')!
	handler := openrpc.new_handler(spec)

	server.handler_registry.register('comments', handler, spec)

	// Start server
	go server.start()

	assert true
}