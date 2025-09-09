#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.heropods

// Initialize factory
mut factory := heropods.new(
	reset:      false
	use_podman: true
) or { panic('Failed to init ContainerFactory: ${err}') }

println('=== HeroPods Refactored API Demo ===')

// Step 1: factory.new() now only creates a container definition/handle
// It does NOT create the actual container in the backend yet
mut container := factory.new(
	name:              'myalpine'
	image:             .custom
	custom_image_name: 'alpine_3_20'
	docker_url:        'docker.io/library/alpine:3.20'
)!

println('✓ Container definition created: ${container.name}')
println('  (No actual container created in backend yet)')

// Step 2: container.start() handles creation and starting
// - Checks if container exists in backend
// - Creates it if it doesn't exist
// - Starts it if it exists but is stopped
println('\n--- First start() call ---')
container.start()!
println('✓ Container started successfully')

// Step 3: Multiple start() calls are now idempotent
println('\n--- Second start() call (should be idempotent) ---')
container.start()!
println('✓ Second start() call successful - no errors!')

// Step 4: Execute commands in the container and save results
println('\n--- Executing commands in container ---')
result1 := container.exec(cmd: 'ls -la /')!
println('✓ Command executed: ls -la /')
println('Result: ${result1}')

result2 := container.exec(cmd: 'echo "Hello from container!"')!
println('✓ Command executed: echo "Hello from container!"')
println('Result: ${result2}')

result3 := container.exec(cmd: 'uname -a')!
println('✓ Command executed: uname -a')
println('Result: ${result3}')

// Step 5: container.delete() works naturally on the instance
println('\n--- Deleting container ---')
container.delete()!
println('✓ Container deleted successfully')

println('\n=== Demo completed! ===')
println('The refactored API now works as expected:')
println('- factory.new() creates definition only')
println('- container.start() is idempotent')
println('- container.exec() works and returns results')
println('- container.delete() works on instances')
