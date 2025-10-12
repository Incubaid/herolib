#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.ourdb
import os

mut server := ourdb.new_server(
	port:               3000
	allowed_hosts:      ['localhost']
	allowed_operations: ['set', 'get', 'delete']
	secret_key:         'secret'
	config:             ourdb.OurDBConfig{
		path:             '/tmp/ourdb'
		incremental_mode: true
	}
)!

server.run()
