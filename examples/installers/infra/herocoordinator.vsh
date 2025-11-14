#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.infra.herocoordinator

// Example usage of herocoordinator installer
// This will:
// 1. Check and install Redis if not running (required dependency)
// 2. Install Rust if not already installed
// 3. Clone the horus repository
// 4. Build the herocoordinator binary

// Build and install herocoordinator
// This will automatically check and install Redis and Rust if needed
println('Building coordinator from horus repository...')
println('(This will install Redis and Rust if not already installed)\n')

// Call build_coordinator - it will handle all dependencies
herocoordinator.build_coordinator()!

println('\n✅ Herocoordinator built and installed successfully!')
println('Binary location: /hero/var/bin/coordinator')

// Note: To start the service, uncomment the lines below
// (requires proper zinit or screen session setup)
// herocoordinator.start()!
// if herocoordinator.running()! {
// 	println('Herocoordinator is running!')
// }
// herocoordinator.stop()!
// herocoordinator.destroy()!
