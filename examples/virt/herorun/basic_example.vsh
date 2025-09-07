#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.herorun
import freeflowuniverse.herolib.ui.console

// Create container factory
mut factory := herorun.new(reset: false)!

// Create a new Alpine container
mut container := factory.new(name: 'test-alpine', image: .alpine_3_20)!

// Start the container
container.start()!

// Execute commands in the container
result := container.exec(cmd: 'ls -la /', stdout: true)!
console.print_debug('Container ls result: ${result}')

// Test file operations
container.exec(cmd: 'echo "Hello from container" > /tmp/test.txt', stdout: false)!
content := container.exec(cmd: 'cat /tmp/test.txt', stdout: false)!
console.print_debug('File content: ${content}')

// Get container status and resource usage
status := container.status()!
cpu := container.cpu_usage()!
mem := container.mem_usage()!

console.print_debug('Container status: ${status}')
console.print_debug('CPU usage: ${cpu}%')
console.print_debug('Memory usage: ${mem} MB')

// Clean up
container.stop()!
container.delete()!