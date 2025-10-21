#!/usr/bin/env -S v -n -w -gc none -cc gcc -d use_openssl -enable-globals -no-skip-unused run

import incubaid.herolib.hero.heromodels
import incubaid.herolib.hero.db
import time

fn main() {
	// Start the server in a background thread with authentication disabled for testing
	spawn fn () {
		heromodels.new(reset: true, name: 'test') or {
			eprintln('Failed to initialize HeroModels: ${err}')
			exit(1)
		}
		heromodels.server_start(
			name:            'test'
			port:            8080
			auth_enabled:    false // Disable auth for testing
			cors_enabled:    true
			reset:           true
			allowed_origins: [
				'http://localhost:5173',
			]
		) or {
			eprintln('Failed to start HeroModels server: ${err}')
			exit(1)
		}
	}()

	// Keep the main thread alive
	for {
		time.sleep(time.second)
	}
}
