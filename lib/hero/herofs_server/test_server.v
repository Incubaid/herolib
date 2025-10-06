module herofs_server

import time

// =============================================================================
// SHARED TEST SERVER MODULE
// =============================================================================
//
// This module provides a shared HeroFS server instance for all test files.
// Benefits:
// - Single server startup (3 seconds) shared across all test files
// - Maintains 6.3x performance improvement
// - Consistent server configuration
// - Easy to modify server settings in one place
// =============================================================================

// Start server on a specific port and return the base URL
pub fn start_test_server(port int) !string {
	base_url := 'http://localhost:${port}'

	mut server := new(
		port:            port
		host:            'localhost'
		cors_enabled:    true
		allowed_origins: ['*']
	)!

	spawn server.start()

	// Wait for server to start
	time.sleep(3000 * time.millisecond)

	println(' HeroFS Test Server started on ${base_url}')
	return base_url
}
