module zinit

import freeflowuniverse.herolib.schemas.jsonrpc

// Default socket path for Zinit
pub const default_socket_path = '/tmp/zinit.sock'

// ZinitClient is a unified client for interacting with Zinit using OpenRPC
pub struct ZinitClient {
pub mut:
	rpc_client &jsonrpc.Client
}

// new_client creates a new Zinit OpenRPC client
// Parameters:
//   - socket_path: Path to the Zinit Unix socket (default: /tmp/zinit.sock)
// Returns:
//   - A new ZinitClient instance
pub fn new_client(socket_path string) ZinitClient {
	mut cl := jsonrpc.new_unix_socket_client(socket_path)
	return ZinitClient{
		rpc_client: cl
	}
}

// OpenRPCSpec represents the OpenRPC specification
pub struct OpenRPCSpec {
pub:
	openrpc string
	info    OpenRPCInfo
	methods []OpenRPCMethod
}

// OpenRPCInfo represents the info section of the OpenRPC specification
pub struct OpenRPCInfo {
pub:
	version     string
	title       string
	description string
}

// OpenRPCMethod represents a method in the OpenRPC specification
pub struct OpenRPCMethod {
pub:
	name        string
	description string
}

// discover returns the OpenRPC specification for the API
// Returns:
//   - A string representation of the OpenRPC specification
pub fn (mut c ZinitClient) discover() !string {
	// Use a simpler approach - just get the raw response and return it as a string
	request := jsonrpc.new_request_generic('rpc.discover', []string{})

	// Send the request and get the raw response
	raw_response := c.rpc_client.transport.send(request.encode(), jsonrpc.SendParams{
		timeout: 5 // Increase timeout to 5 seconds
	})!

	// Extract just the result part from the response
	// This is a simplified approach to avoid full JSON parsing
	start_idx := raw_response.index('{"info":') or { return error('Invalid response format') }

	// Return the raw JSON string
	return raw_response[start_idx..]
}

// list returns a map of service names to their current states
// Returns:
//   - A map where keys are service names and values are their states
pub fn (mut c ZinitClient) list() !map[string]string {
	request := jsonrpc.new_request_generic('service_list', []string{})
	return c.rpc_client.send[[]string, map[string]string](request)!
}

// ServiceStatus represents the detailed status of a service
pub struct ServiceStatus {
pub:
	name   string
	pid    int
	state  string
	target string
	after  map[string]string
}

// status returns detailed status information for a specific service
// Parameters:
//   - name: The name of the service to get status for
// Returns:
//   - A ServiceStatus struct containing detailed status information
pub fn (mut c ZinitClient) status(name string) !ServiceStatus {
	request := jsonrpc.new_request_generic('service_status', name)
	return c.rpc_client.send[string, ServiceStatus](request)!
}

// EmptyResponse represents an empty response from the API
pub struct EmptyResponse {}

// start starts a service
// Parameters:
//   - name: The name of the service to start
pub fn (mut c ZinitClient) start(name string) ! {
	request := jsonrpc.new_request_generic('service_start', name)
	c.rpc_client.send[string, EmptyResponse](request)!
}

// stop stops a service
// Parameters:
//   - name: The name of the service to stop
pub fn (mut c ZinitClient) stop(name string) ! {
	request := jsonrpc.new_request_generic('service_stop', name)
	c.rpc_client.send[string, EmptyResponse](request)!
}

// monitor starts monitoring a service
// Parameters:
//   - name: The name of the service to monitor
pub fn (mut c ZinitClient) monitor(name string) ! {
	request := jsonrpc.new_request_generic('service_monitor', name)
	c.rpc_client.send[string, EmptyResponse](request)!
}

// forget stops monitoring a service
// Parameters:
//   - name: The name of the service to forget
pub fn (mut c ZinitClient) forget(name string) ! {
	request := jsonrpc.new_request_generic('service_forget', name)
	c.rpc_client.send[string, EmptyResponse](request)!
}

// KillParams represents the parameters for the kill method
pub struct KillParams {
pub:
	name   string
	signal string
}

// kill sends a signal to a running service
// Parameters:
//   - name: The name of the service to send the signal to
//   - signal: The signal to send (e.g., SIGTERM, SIGKILL)
pub fn (mut c ZinitClient) kill(name string, signal string) ! {
	params := KillParams{
		name:   name
		signal: signal
	}

	request := jsonrpc.new_request_generic('service_kill', params)
	c.rpc_client.send[KillParams, EmptyResponse](request)!
}

// shutdown stops all services and powers off the system
pub fn (mut c ZinitClient) shutdown() ! {
	request := jsonrpc.new_request_generic('system_shutdown', []string{})
	c.rpc_client.send[[]string, EmptyResponse](request)!
}

// reboot stops all services and reboots the system
pub fn (mut c ZinitClient) reboot() ! {
	request := jsonrpc.new_request_generic('system_reboot', []string{})
	c.rpc_client.send[[]string, EmptyResponse](request)!
}

// ServiceStats represents memory and CPU usage statistics for a service
pub struct ServiceStats {
pub:
	name         string
	pid          int
	memory_usage i64
	cpu_usage    f64
	children     []ChildProcessStats
}

// ChildProcessStats represents statistics for a child process
pub struct ChildProcessStats {
pub:
	pid          int
	memory_usage i64
	cpu_usage    f64
}

// stats returns memory and CPU usage statistics for a service
// Parameters:
//   - name: The name of the service to get stats for
// Returns:
//   - A ServiceStats struct containing memory and CPU usage statistics
pub fn (mut c ZinitClient) stats(name string) !ServiceStats {
	request := jsonrpc.new_request_generic('service_stats', name)
	return c.rpc_client.send[string, ServiceStats](request)!
}

// get_logs returns current logs from a specific service
// Parameters:
//   - name: The name of the service to get logs for
// Returns:
//   - An array of log strings
pub fn (mut c ZinitClient) get_logs(name string) ![]string {
	request := jsonrpc.new_request_generic('stream_currentLogs', name)
	return c.rpc_client.send[string, []string](request)!
}

// get_all_logs returns all current logs from zinit and monitored services
// Returns:
//   - An array of log strings
pub fn (mut c ZinitClient) get_all_logs() ![]string {
	request := jsonrpc.new_request_generic('stream_currentLogs', []string{})
	return c.rpc_client.send[[]string, []string](request)!
}

// ServiceConfig represents the configuration for a service
pub struct ServiceConfig {
pub:
	exec             string
	oneshot          bool
	after            []string
	log              string
	env              map[string]string
	shutdown_timeout int
}

// CreateServiceParams represents the parameters for the create_service method
pub struct CreateServiceParams {
pub:
	name    string
	content ServiceConfig
}

// create_service creates a new service configuration file
// Parameters:
//   - name: The name of the service to create
//   - config: The service configuration
// Returns:
//   - A string indicating the result of the operation
pub fn (mut c ZinitClient) create_service(name string, config ServiceConfig) !string {
	params := CreateServiceParams{
		name:    name
		content: config
	}

	request := jsonrpc.new_request_generic('service_create', params)
	return c.rpc_client.send[CreateServiceParams, string](request)!
}

// delete_service deletes a service configuration file
// Parameters:
//   - name: The name of the service to delete
// Returns:
//   - A string indicating the result of the operation
pub fn (mut c ZinitClient) delete_service(name string) !string {
	request := jsonrpc.new_request_generic('service_delete', name)
	return c.rpc_client.send[string, string](request)!
}

// ServiceConfigResponse represents the response from get_service
pub struct ServiceConfigResponse {
pub:
	exec             string
	oneshot          bool
	after            []string
	log              string
	env              map[string]string
	shutdown_timeout int
}

// get_service gets a service configuration file
// Parameters:
//   - name: The name of the service to get
// Returns:
//   - The service configuration
pub fn (mut c ZinitClient) get_service(name string) !ServiceConfigResponse {
	request := jsonrpc.new_request_generic('service_get', name)
	return c.rpc_client.send[string, ServiceConfigResponse](request)!
}

// start_http_server starts an HTTP/RPC server at the specified address
// Parameters:
//   - address: The network address to bind the server to (e.g., '127.0.0.1:8080')
// Returns:
//   - A string indicating the result of the operation
pub fn (mut c ZinitClient) start_http_server(address string) !string {
	request := jsonrpc.new_request_generic('system_start_http_server', address)
	return c.rpc_client.send[string, string](request)!
}

// stop_http_server stops the HTTP/RPC server if running
pub fn (mut c ZinitClient) stop_http_server() ! {
	request := jsonrpc.new_request_generic('system_stop_http_server', []string{})
	c.rpc_client.send[[]string, EmptyResponse](request)!
}
