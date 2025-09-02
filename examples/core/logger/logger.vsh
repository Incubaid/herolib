#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.core.logger

mut l := logger.new(path: '/tmp/vlogs')!

l.log(
	cat:     'system'
	log:     'System started successfully'
	logtype: .stdout
)!

l.log(
	cat:     'system'
	log:     'Failed to connect\nRetrying in 5 seconds...'
	logtype: .error
)!
