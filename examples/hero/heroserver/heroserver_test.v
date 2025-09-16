import freeflowuniverse.herolib.hero.heroserver

fn testsuite_begin() {
	// a clean start
	// os.rm('./db')! //TODO: was giving issues
}

fn test_heroserver_new() {
	// Create server
	mut server := heroserver.new_server(heroserver.ServerConfig{
		port:        8080
		auth_config: heroserver.AuthConfig{}
	})!

	// Test that server was created successfully
	assert server.config.port == 8080
	assert true
}
