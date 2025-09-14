module heroserver

@[params]
pub struct ServerConfig {
pub:
	port int    = 8080
	host string = 'localhost'
}

// Factory function to create new server instance
pub fn new_server(config ServerConfig) !&HeroServer {
	mut server := &HeroServer{
		config:           config
		auth_manager:     new_auth_manager()
		handler_registry: new_handler_registry()
	}
	return server
}
