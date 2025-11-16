#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.horus.coordinator

// Example usage of coordinator installer
// This will:
// 1. Check and install Redis if not running (required dependency)
// 2. Install Rust if not already installed
// 3. Clone the horus repository
// 4. Build the coordinator binary

println('Building coordinator from horus repository...')
println('(This will install Redis and Rust if not already installed)\n')

// Create coordinator instance - will auto-install Redis if needed
mut coord := coordinator.new()!

// Build and install
coord.install()!

println('\nCoordinator built and installed successfully!')
println('Binary location: ${coord.binary_path}')

// Note: To start the service, uncomment the lines below
// (requires proper zinit or screen session setup)
// coord.start()!
// if coord.running()! {
// 	println('Coordinator is running!')
// }
// coord.stop()!
// coord.destroy()!
