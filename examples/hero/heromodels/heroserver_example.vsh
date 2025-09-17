#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.hero.heromodels.rpc
import freeflowuniverse.herolib.hero.heromodels
import time

fn main() {
	// Start the server in a background thread
	spawn fn () {
		rpc.start(port: 8080) or { panic('Failed to start HeroModels server: ${err}') }
	}()

	// Keep the main thread alive
	for {
		time.sleep(time.second)
	}
}
