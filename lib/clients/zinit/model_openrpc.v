module zinit

// ServiceStatus represents detailed status information for a service
pub struct ServiceStatus {
pub mut:
	name   string            // Service name
	pid    u32               // Process ID of the running service (if running)
	state  string            // Current state of the service (Running, Success, Error, etc.)
	target string            // Target state of the service (Up, Down)
	after  map[string]string // Dependencies of the service and their states
}

// ServiceConfig represents the configuration for a zinit service
pub struct ServiceConfig {
pub mut:
	exec             string            // Command to run
	test             string            // Test command (optional)
	oneshot          bool              // Whether the service should be restarted (maps to one_shot in Zinit)
	after            []string          // Services that must be running before this one starts
	log              string            // How to handle service output (null, ring, stdout)
	env              map[string]string // Environment variables for the service
	dir              string            // Working directory for the service
	shutdown_timeout u64               // Maximum time to wait for service to stop during shutdown
}

// ServiceStats represents memory and CPU usage statistics for a service
pub struct ServiceStats {
pub mut:
	name         string       // Service name
	pid          u32          // Process ID of the service
	memory_usage u64          // Memory usage in bytes
	cpu_usage    f32          // CPU usage as a percentage (0-100)
	children     []ChildStats // Stats for child processes
}

// ChildStats represents statistics for a child process
pub struct ChildStats {
pub mut:
	pid          u32 // Process ID of the child process
	memory_usage u64 // Memory usage in bytes
	cpu_usage    f32 // CPU usage as a percentage (0-100)
}

// ServiceCreateParams represents parameters for service_create method
pub struct ServiceCreateParams {
pub mut:
	name    string        // Name of the service to create
	content ServiceConfig // Configuration for the service
}

// ServiceKillParams represents parameters for service_kill method
pub struct ServiceKillParams {
pub mut:
	name   string // Name of the service to kill
	signal string // Signal to send (e.g., SIGTERM, SIGKILL)
}

// LogParams represents parameters for log streaming methods
@[params]
pub struct LogParams {
pub mut:
	name string // Optional service name filter
}
