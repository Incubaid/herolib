# Zinit OpenRPC Client

This module provides a V language client for interacting with Zinit process manager using the OpenRPC protocol over a Unix socket.

## Overview

Zinit is a process manager that allows you to manage services on a system. This client provides a way to interact with Zinit using its JSON-RPC API, which follows the OpenRPC specification.

## Features

- Full implementation of the Zinit OpenRPC API
- Type-safe request and response handling
- Support for all Zinit operations:
  - Service management (start, stop, monitor, forget)
  - Service status and statistics
  - System operations (shutdown, reboot)
  - Log retrieval
  - Service configuration management

## Usage

### Basic Usage

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    // Create a new Zinit client with the default socket path
    mut zinit_client := zinit.new_stateless()!
    
    // List all services
    service_list := zinit_client.client.list()!
    println('Services:')
    for name, state in service_list {
        println('- ${name}: ${state}')
    }
    
    // Start a service
    zinit_client.client.start('my_service')!
    
    // Get service status
    status := zinit_client.client.status('my_service')!
    println('Service state: ${status.state}')
}
```

### Creating a New Service

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut zinit_client := zinit.new_stateless()!
    
    // Define service configuration
    service_config := zinit.ServiceConfig{
        exec: '/usr/bin/my-program --option value'
        oneshot: false
        after: ['dependency1', 'dependency2']
        log: 'stdout'
        env: {
            'ENV_VAR1': 'value1'
            'ENV_VAR2': 'value2'
        }
        shutdown_timeout: 30
    }
    
    // Create the service
    zinit_client.client.create_service('my_service', service_config)!
    
    // Monitor and start the service
    zinit_client.client.monitor('my_service')!
    zinit_client.client.start('my_service')!
}
```

### Getting Service Statistics

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut zinit_client := zinit.new_stateless()!
    
    // Get service stats
    stats := zinit_client.client.stats('my_service')!
    
    println('Memory usage: ${stats.memory_usage} bytes')
    println('CPU usage: ${stats.cpu_usage}%')
    
    // Print child process stats
    for child in stats.children {
        println('Child PID: ${child.pid}, Memory: ${child.memory_usage} bytes')
    }
}
```

### Retrieving Logs

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut zinit_client := zinit.new_stateless()!
    
    // Get logs for a specific service
    logs := zinit_client.client.get_logs('my_service')!
    for log in logs {
        println(log)
    }
    
    // Get all logs
    all_logs := zinit_client.client.get_all_logs()!
    for log in all_logs {
        println(log)
    }
}
```

## API Reference

### Client Methods

- `discover()` - Returns the OpenRPC specification for the API
- `list()` - Returns a map of service names to their current states
- `status(name string)` - Returns detailed status information for a specific service
- `start(name string)` - Starts a service
- `stop(name string)` - Stops a service
- `monitor(name string)` - Starts monitoring a service
- `forget(name string)` - Stops monitoring a service
- `kill(name string, signal string)` - Sends a signal to a running service
- `shutdown()` - Stops all services and powers off the system
- `reboot()` - Stops all services and reboots the system
- `stats(name string)` - Returns memory and CPU usage statistics for a service
- `get_logs(name string)` - Returns current logs from a specific service
- `get_all_logs()` - Returns all current logs from zinit and monitored services
- `create_service(name string, config ServiceConfig)` - Creates a new service configuration file
- `delete_service(name string)` - Deletes a service configuration file
- `get_service(name string)` - Gets a service configuration file
- `start_http_server(address string)` - Starts an HTTP/RPC server at the specified address
- `stop_http_server()` - Stops the HTTP/RPC server if running

### Data Structures

- `ServiceStatus` - Detailed status information for a service
- `ServiceStats` - Memory and CPU usage statistics for a service
- `ServiceConfig` - Configuration for creating a new service

## OpenRPC Specification

The full OpenRPC specification for the Zinit API is available in the `openrpc.json` file. This specification defines all the methods, parameters, and return types for the API.

## Example

See the `examples/osal/zinit/zinit_openrpc_example.v` file for a complete example of using the Zinit OpenRPC client.