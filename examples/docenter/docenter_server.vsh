#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import incubaid.herolib.docenter
import os

// Configuration
const server_port = 8004

fn main() {
	// Get the directory where this script is located
	// We use the script directory for the data path to ensure data persistence
	// regardless of where the script is run from (e.g., ./docenter_server.vsh vs /path/to/docenter_server.vsh)
	script_dir := os.dir(os.real_path(@FILE))
	data_dir := os.join_path(script_dir, 'data')

	// Create docenter server
	mut config := docenter.ServerConfig{
		user_db:  {
			'admin': '123'
		}
		data_dir: data_dir
	}
	mut server := docenter.new_server(mut config)!
	server.run(server_port)
}
