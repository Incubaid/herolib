module zinit

import json
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.schemas.openrpc

// Helper function to get or create the RPC client
fn (mut c ZinitRPC) client_() !&jsonrpc.Client {
	// Create Unix socket client
	mut client := jsonrpc.new_unix_socket_client(c.socket_path)
	return client
}

// Admin methods

// rpc_discover returns the OpenRPC specification for the API
pub fn (mut c ZinitRPC) rpc_discover() !openrpc.OpenRPC {
	mut client := c.client_()!
	request := jsonrpc.new_request('rpc.discover', '')
	openrpc_str := client.send_str(request)!
	return json.decode(openrpc.OpenRPC, openrpc_str)
}

// service_list lists all services managed by Zinit
// Returns a map of service names to their current states
pub fn (mut c ZinitRPC) service_list() !map[string]string {
	mut client := c.client_()!
	request := jsonrpc.new_request_generic('service_list', []string{})
	return client.send[[]string, map[string]string](request)!
}

// service_status shows detailed status information for a specific service
pub fn (mut c ZinitRPC) service_status(name string) !ServiceStatus {
	mut client := c.client_()!
	params := {
		'name': name
	}
	request := jsonrpc.new_request_generic('service_status', params)
	return client.send[map[string]string, ServiceStatus](request)!
}

// service_start starts a service
pub fn (mut c ZinitRPC) service_start(name string) ! {
	mut client := c.client_()!
	params := {
		'name': name
	}
	request := jsonrpc.new_request_generic('service_start', params)
	client.send[map[string]string, string](request)!
}

// service_stop stops a service
pub fn (mut c ZinitRPC) service_stop(name string) ! {
	mut client := c.client_()!
	params := {
		'name': name
	}
	request := jsonrpc.new_request_generic('service_stop', params)
	client.send[map[string]string, string](request)!
}

// service_monitor starts monitoring a service
// The service configuration is loaded from the config directory
pub fn (mut c ZinitRPC) service_monitor(name string) ! {
	mut client := c.client_()!
	params := {
		'name': name
	}
	request := jsonrpc.new_request_generic('service_monitor', params)
	client.send[map[string]string, string](request)!
}

// service_forget stops monitoring a service
// You can only forget a stopped service
pub fn (mut c ZinitRPC) service_forget(name string) ! {
	mut client := c.client_()!
	params := {
		'name': name
	}
	request := jsonrpc.new_request_generic('service_forget', params)
	client.send[map[string]string, string](request)!
}

// service_kill sends a signal to a running service
pub fn (mut c ZinitRPC) service_kill(name string, signal string) ! {
	mut client := c.client_()!
	params := ServiceKillParams{
		name:   name
		signal: signal
	}
	request := jsonrpc.new_request_generic('service_kill', params)
	client.send[ServiceKillParams, string](request)!
}

// service_create creates a new service configuration file
pub fn (mut c ZinitRPC) service_create(name string, config ServiceConfig) !string {
	mut client := c.client_()!
	params := ServiceCreateParams{
		name:    name
		content: config
	}
	request := jsonrpc.new_request_generic('service_create', params)
	return client.send[ServiceCreateParams, string](request)!
}

// service_delete deletes a service configuration file
pub fn (mut c ZinitRPC) service_delete(name string) !string {
	mut client := c.client_()!
	params := {
		'name': name
	}
	request := jsonrpc.new_request_generic('service_delete', params)
	return client.send[map[string]string, string](request)!
}

// service_get gets a service configuration file
pub fn (mut c ZinitRPC) service_get(name string) !ServiceConfig {
	mut client := c.client_()!
	params := {
		'name': name
	}
	request := jsonrpc.new_request_generic('service_get', params)
	return client.send[map[string]string, ServiceConfig](request)!
}

// service_stats gets memory and CPU usage statistics for a service
pub fn (mut c ZinitRPC) service_stats(name string) !ServiceStats {
	mut client := c.client_()!
	params := {
		'name': name
	}
	request := jsonrpc.new_request_generic('service_stats', params)
	return client.send[map[string]string, ServiceStats](request)!
}

// System methods

// system_shutdown stops all services and powers off the system
pub fn (mut c ZinitRPC) system_shutdown() ! {
	mut client := c.client_()!
	request := jsonrpc.new_request_generic('system_shutdown', []string{})
	client.send[[]string, string](request)!
}

// system_reboot stops all services and reboots the system
pub fn (mut c ZinitRPC) system_reboot() ! {
	mut client := c.client_()!
	request := jsonrpc.new_request_generic('system_reboot', []string{})
	client.send[[]string, string](request)!
}

// system_start_http_server starts an HTTP/RPC server at the specified address
pub fn (mut c ZinitRPC) system_start_http_server(address string) !string {
	mut client := c.client_()!
	params := {
		'address': address
	}
	request := jsonrpc.new_request_generic('system_start_http_server', params)
	return client.send[map[string]string, string](request)!
}

// system_stop_http_server stops the HTTP/RPC server if running
pub fn (mut c ZinitRPC) system_stop_http_server() ! {
	mut client := c.client_()!
	request := jsonrpc.new_request_generic('system_stop_http_server', []string{})
	client.send[[]string, string](request)!
}

// Streaming methods

// stream_current_logs gets current logs from zinit and monitored services
pub fn (mut c ZinitRPC) stream_current_logs(args LogParams) ![]string {
	mut client := c.client_()!
	if args.name != '' {
		params := {
			'name': args.name
		}
		request := jsonrpc.new_request_generic('stream_currentLogs', params)
		return client.send[map[string]string, []string](request)!
	} else {
		request := jsonrpc.new_request_generic('stream_currentLogs', []string{})
		return client.send[[]string, []string](request)!
	}
}

// stream_subscribe_logs subscribes to log messages generated by zinit and monitored services
// Returns a subscription ID that can be used to manage the subscription
pub fn (mut c ZinitRPC) stream_subscribe_logs(args LogParams) !u64 {
	mut client := c.client_()!
	if args.name != '' {
		params := {
			'name': args.name
		}
		request := jsonrpc.new_request_generic('stream_subscribeLogs', params)
		return client.send[map[string]string, u64](request)!
	} else {
		request := jsonrpc.new_request_generic('stream_subscribeLogs', []string{})
		return client.send[[]string, u64](request)!
	}
}
