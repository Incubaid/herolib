#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.base

println('=== Testing Redis Template Application ===\n')

// Stop redis first
println('Stopping redis...')
base.stop() or {}

// Start redis (this will apply the template)
println('Starting redis with template...')
base.start(port: 6379, datadir: '/root/hero/var/redis')!

println('✅ Redis started')

// Verify it's running
if base.check(port: 6379) {
	println('✅ Redis is responding to ping')
} else {
	println('❌ Redis is not responding')
}

println('\n✅ Done!')
