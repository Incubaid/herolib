#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.base.redis

println('=== Redis Installer Example ===\n')

// Create configuration
// You can customize port, datadir, and ipaddr as needed
config := redis.RedisInstall{
	port: 6379                  // Redis port
	datadir: '/var/lib/redis'   // Data directory (standard location)
	ipaddr: 'localhost'         // Bind address
}

// Check if Redis is already running
if redis.check(config) {
	println('INFO: Redis is already running on port ${config.port}')
	println('      To reinstall, stop Redis first: redis.stop()!')
} else {
	// Install and start Redis
	println('Installing and starting Redis...')
	println('  Port: ${config.port}')
	println('  Data directory: ${config.datadir}')
	println('  Bind address: ${config.ipaddr}\n')
	
	redis.redis_install(config)!
	
	// Verify installation
	if redis.check(config) {
		println('\nSUCCESS: Redis installed and started successfully!')
		println('         You can now connect to Redis on port ${config.port}')
		println('         Test with: redis-cli ping')
	} else {
		println('\nERROR: Redis installation completed but failed to start')
		println('       Check logs: journalctl -u redis-server -n 20')
	}
}

println('\n=== Available Functions ===')
println('  redis.redis_install(config)!  - Install and start Redis')
println('  redis.start(config)!          - Start Redis')
println('  redis.stop()!                 - Stop Redis')
println('  redis.restart(config)!        - Restart Redis')
println('  redis.check(config)           - Check if running')

println('\nDone!')
