#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.hero.db
import time

fn main() {
	// Start the server in a background thread with authentication disabled for testing
	spawn fn () ! {
		heromodels.new(reset: true, name: 'test')!
		heromodels.server_start(
			name:            'test'
			port:            8080
			auth_enabled:    false // Disable auth for testing
			cors_enabled:    true
			reset:           true
			allowed_origins: [
				'http://localhost:5173',
			]
		) or { panic('Failed to start HeroModels server: ${err}') }
	}()

	// Keep the main thread alive
	for {
		time.sleep(time.second)
	}
}
