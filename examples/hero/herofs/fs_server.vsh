#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.hero.herofs_server
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.redisclient
import os

fn main() {
	console.print_header('HeroFS REST API Server Example')

	// Environment variable configuration with defaults
	redis_host := os.getenv_opt('REDIS_HOST') or { 'localhost' }
	redis_port := (os.getenv_opt('REDIS_PORT') or { '6379' }).int()
	server_port := (os.getenv_opt('SERVER_PORT') or { '8080' }).int()
	server_host := os.getenv_opt('SERVER_HOST') or { 'localhost' }
	cors_enabled := (os.getenv_opt('CORS_ENABLED') or { 'true' }).bool()
	allowed_origin := os.getenv_opt('ALLOWED_ORIGIN') or { '*' }

	// Configure Redis connection for main database
	mut redis := redisclient.core_get(redisclient.RedisURL{
		address: redis_host
		port: redis_port
	})!

	mut server := herofs_server.new(
		port:            server_port
		host:            server_host
		cors_enabled:    cors_enabled
		allowed_origins: [allowed_origin]
		redis:           redis
	)!

	console.print_item('Server configured successfully')
		console.print_item('Starting server...')
		console.print_item('')
		console.print_item('Available endpoints:')
		console.print_item('  Health check: GET http://${server_host}:${server_port}/health')
		console.print_item('  API info: GET http://${server_host}:${server_port}/api')
		console.print_item('  Filesystems: http://${server_host}:${server_port}/api/fs')
		console.print_item('  Directories: http://${server_host}:${server_port}/api/dirs')
		console.print_item('  Files: http://${server_host}:${server_port}/api/files')
		console.print_item('  Blobs: http://${server_host}:${server_port}/api/blobs')
		console.print_item('  Symlinks: http://${server_host}:${server_port}/api/symlinks')
		console.print_item('  Tools: http://${server_host}:${server_port}/api/tools')
		console.print_item('')
		console.print_item('Press Ctrl+C to stop the server')

		// Start the server (this blocks)
		server.start()!
}
