# Zinit RPC Client

This is a V language client for the Zinit process manager, implementing the JSON-RPC API specification for service management operations.

## Overview

Zinit is a process manager that provides service monitoring, dependency management, and system control capabilities. This client provides a comprehensive API to interact with Zinit via its JSON-RPC interface for administrative tasks such as:

- Service lifecycle management (start, stop, monitor, forget)
- Service configuration management (create, delete, get)
- Service status and statistics monitoring
- System operations (shutdown, reboot, HTTP server control)
- Log streaming and monitoring

## Features

- **✅ 100% API Coverage**: Complete implementation of all 18 methods in the Zinit JSON-RPC specification
- **✅ Production Tested**: All methods tested and working against real Zinit instances
- **✅ Type-safe API**: Proper V struct definitions with comprehensive error handling
- **✅ Subscription Support**: Proper handling of streaming/subscription methods
- **✅ Unix Socket Transport**: Reliable communication via Unix domain sockets
- **✅ Comprehensive Documentation**: Extensive documentation with working examples

## Usage

### Basic Example

```v
import freeflowuniverse.herolib.clients.zinit

// Create a new client
mut client := zinit.get(create:true)!

// List all services
services := client.service_list()!
for service_name, state in services {
    println('Service: ${service_name}, State: ${state}')
}

// Get detailed status of a specific service
status := client.service_status('redis')!
println('Service: ${status.name}')
println('PID: ${status.pid}')
println('State: ${status.state}')
println('Target: ${status.target}')

// Start a service
client.service_start('redis')!

// Stop a service
client.service_stop('redis')!
```

### Service Configuration Management

```v
import freeflowuniverse.herolib.clients.zinit

mut client := zinit.new_client()!

// Create a new service configuration
config := zinit.ServiceConfig{
    exec: '/usr/bin/redis-server'
    oneshot: false
    log: 'stdout'
    env: {
        'REDIS_PORT': '6379'
        'REDIS_HOST': '0.0.0.0'
    }
    shutdown_timeout: 30
}

// Create the service
path := client.service_create('redis', config)!
println('Service created at: ${path}')

// Get service configuration
retrieved_config := client.service_get('redis')!
println('Service exec: ${retrieved_config.exec}')

// Delete service configuration
result := client.service_delete('redis')!
println('Delete result: ${result}')
```

### Service Statistics

```v
import freeflowuniverse.herolib.clients.zinit

mut client := zinit.new_client()!

// Get service statistics
stats := client.service_stats('redis')!
println('Service: ${stats.name}')
println('PID: ${stats.pid}')
println('Memory Usage: ${stats.memory_usage} bytes')
println('CPU Usage: ${stats.cpu_usage}%')

// Print child process statistics
for child in stats.children {
    println('Child PID: ${child.pid}, Memory: ${child.memory_usage}, CPU: ${child.cpu_usage}%')
}
```

### Log Streaming

```v
import freeflowuniverse.herolib.clients.zinit

mut client := zinit.new_client()!

// Get current logs for all services
logs := client.stream_current_logs(name: '')!
for log in logs {
    println(log)
}

// Get current logs for a specific service
redis_logs := client.stream_current_logs(name: 'redis')!
for log in redis_logs {
    println('Redis: ${log}')
}

// Subscribe to log stream (returns subscription ID)
subscription_id := client.stream_subscribe_logs(name: 'redis')!
println('Subscribed to logs with ID: ${subscription_id}')
```

## API Reference

### Service Management Methods

- `service_list()` - List all services and their states
- `service_status(name)` - Get detailed status of a service
- `service_start(name)` - Start a service
- `service_stop(name)` - Stop a service
- `service_monitor(name)` - Start monitoring a service
- `service_forget(name)` - Stop monitoring a service
- `service_kill(name, signal)` - Send signal to a service

### Service Configuration Methods

- `service_create(name, config)` - Create service configuration
- `service_delete(name)` - Delete service configuration
- `service_get(name)` - Get service configuration

### Monitoring Methods

- `service_stats(name)` - Get service statistics

### System Methods

- `system_shutdown()` - Shutdown the system
- `system_reboot()` - Reboot the system
- `system_start_http_server(address)` - Start HTTP server
- `system_stop_http_server()` - Stop HTTP server

### Streaming Methods

- `stream_current_logs(args)` - Get current logs (returns array of log lines)
- `stream_subscribe_logs(args)` - Subscribe to log stream (returns subscription ID)

### Discovery Methods

- `rpc_discover()` - Get OpenRPC specification

## Configuration

### Using the Factory Pattern

```v
import freeflowuniverse.herolib.clients.zinit

// Get client using factory (recommended)
mut client := zinit.get()!

// Use the client
services := client.service_list()!
```

### Example Heroscript Configuration

```hero
!!zinit.configure
    name: 'production'
    socket_path: '/tmp/zinit.sock'
```

## Error Handling

The client provides comprehensive error handling for all Zinit-specific error codes:

- `-32000`: Service not found
- `-32001`: Service already monitored
- `-32002`: Service is up
- `-32003`: Service is down
- `-32004`: Invalid signal
- `-32005`: Config error
- `-32006`: Shutting down
- `-32007`: Service already exists
- `-32008`: Service file error

```v
import freeflowuniverse.herolib.clients.zinit

mut client := zinit.new_client()!

// Handle specific errors
client.service_start('nonexistent') or {
    if err.msg().contains('Service not found') {
        println('Service does not exist')
    } else {
        println('Other error: ${err}')
    }
}
```


