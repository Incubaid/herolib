#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import incubaid.herolib.docenter
import os

// Configuration
const server_port = 8004

// Create docenter server
mut config := docenter.ServerConfig{
	user_db: {
		'admin': '123'
	}
}
mut server := docenter.new_server(mut config)!
server.run(server_port)
