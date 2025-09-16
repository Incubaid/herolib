#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heroserver

mut server := heroserver.new_server(heroserver.ServerConfig{
	port:        8080
	auth_config: heroserver.AuthConfig{}
})!
server.start()!
