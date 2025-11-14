#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.base
import incubaid.herolib.osal.core as osal
import time

println('=== Redis Installer Example ===\n')

// Check if redis is already installed
if osal.cmd_exists_profile('redis-server') {
	println('✅ redis-server is already installed')
	
	// Check if it's running
	if base.check(port: 6379) {
		println('✅ Redis is running and responding')
	} else {
		println('⚠️  Redis is installed but not running, starting it...')
		// Use systemctl to start redis
		osal.exec(cmd: 'systemctl start redis-server')!
		
		// Wait a moment for redis to start
		time.sleep(1000)
		
		if base.check(port: 6379) {
			println('✅ Redis started successfully')
		} else {
			println('❌ Failed to start redis')
		}
	}
} else {
	println('Redis not found, installing...')
	
	// Install and start redis
	base.redis_install(port: 6379, start: true)!
	
	println('✅ Redis installed and started successfully')
}

println('\n✅ Done!')
