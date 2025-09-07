#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.herorun
import freeflowuniverse.herolib.builder
import freeflowuniverse.herolib.ui.console

// Create container
mut factory := herorun.new()!
mut container := factory.new(name: 'builder-test', image: .ubuntu_24_04)!
container.start()!

// Get builder node for the container
mut node := container.node()!

// Use builder methods to interact with container
node.file_write('/tmp/script.sh', '
#!/bin/bash
echo "Running from builder node"
whoami
pwd
ls -la /
')!

result := node.exec(cmd: 'chmod +x /tmp/script.sh && /tmp/script.sh', stdout: true)!
console.print_debug('Builder execution result: ${result}')

// Test file operations through builder
exists := node.file_exists('/tmp/script.sh')
console.print_debug('Script exists: ${exists}')

content := node.file_read('/tmp/script.sh')!
console.print_debug('Script content: ${content}')

// Clean up
container.stop()!
container.delete()!