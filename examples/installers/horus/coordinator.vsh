#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.horus.coordinator

// Example usage of coordinator installer
// This will:
// 1. Check if Rust is installed (installs if not present)
// 2. Clone the horus repository
// 3. Build the coordinator binary
//
// Note: Redis must be pre-installed and running before using the coordinator

println('Building coordinator from horus repository...')
println('(This will install Rust if not already installed)\n')

// Create coordinator instance
mut coord := coordinator.new()!

// Build and install
// Note: This will skip the build if the binary already exists
coord.install()!

// To force a rebuild even if binary exists, use:
// coord.install(reset: true)!

println('\nCoordinator built and installed successfully!')
println('Binary location: ${coord.binary_path}')

// Note: To start the service, uncomment the lines below
// (requires proper zinit or screen session setup and Redis running)
// coord.start()!
// if coord.running()! {
// 	println('Coordinator is running!')
// }
// coord.stop()!
// coord.destroy()!
