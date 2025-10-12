#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import incubaid.herolib.hero.herofs_server
import incubaid.herolib.ui.console

fn main() {
	console.print_header('HeroFS REST API Server Example')

	// Create server with CORS enabled for development
	mut server := herofs_server.new(
		port:            8080
		host:            'localhost'
		cors_enabled:    true
		allowed_origins: ['*'] // Allow all origins for development
	)!

	console.print_item('Server configured successfully')
	console.print_item('Starting server...')
	console.print_item('')
	console.print_item('Available endpoints:')
	console.print_item('  Health check: GET http://localhost:8080/health')
	console.print_item('  API info: GET http://localhost:8080/api')
	console.print_item('  Filesystems: http://localhost:8080/api/fs')
	console.print_item('  Directories: http://localhost:8080/api/dirs')
	console.print_item('  Files: http://localhost:8080/api/files')
	console.print_item('  Blobs: http://localhost:8080/api/blobs')
	console.print_item('  Symlinks: http://localhost:8080/api/symlinks')
	console.print_item('  Tools: http://localhost:8080/api/tools')
	console.print_item('')
	console.print_item('Press Ctrl+C to stop the server')

	// Start the server (this blocks)
	server.start()!
}
