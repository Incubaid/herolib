# SystemD Module

A V module for managing systemd services with comprehensive error handling and monitoring capabilities.

## Features

- Create, start, stop, and delete systemd services
- Service status monitoring with detailed error reporting
- Journal log retrieval with filtering options
- Health checks for service validation
- Automatic retry logic for service operations

## Quick Start

```v
import freeflowuniverse.herolib.lib.osal.systemd

// Create systemd factory
mut systemd := systemd.new()!

// Create a new service
mut redis_service := systemd.new(
    name: 'redis_custom'
    cmd: 'redis-server /etc/redis/redis.conf'
    description: 'Custom Redis server'
    start: true
)!

// Check service status
status := redis_service.status()!
println('Redis service status: ${status}')

// Get service logs
logs := redis_service.get_logs(50)!
println('Recent logs:\n${logs}')
```

## Creating Services

### Basic Service

```v
mut service := systemd.new(
    name: 'my_service'
    cmd: '/usr/bin/my_application --config /etc/my_app.conf'
    description: 'My custom application'
    start: true
)!
```

### Service with Environment Variables

```v
mut service := systemd.new(
    name: 'web_app'
    cmd: '/usr/bin/webapp'
    description: 'Web application server'
    env: {
        'PORT': '8080'
        'ENV': 'production'
        'DB_HOST': 'localhost'
    }
    start: true
)!
```

### Service with Complex Command

```v
// For multi-line commands, systemd will create a script file
mut service := systemd.new(
    name: 'backup_service'
    cmd: '
        #!/bin/bash
        cd /var/backups
        tar -czf backup_$(date +%Y%m%d).tar.gz /home/data/
        aws s3 cp backup_$(date +%Y%m%d).tar.gz s3://my-bucket/
    '
    description: 'Daily backup service'
    start: true
)!
```

## Service Management

### Starting and Stopping Services

```v
// Start service (with automatic verification)
service.start()! // Will wait and verify service started successfully

// Stop service (with verification)
service.stop()! // Will wait and verify service stopped

// Restart service
service.restart()!
```

### Checking Service Status

```v
// Get simple status
status := service.status()!
match status {
    .active { println('Service is running') }
    .failed { println('Service has failed') }
    .inactive { println('Service is stopped') }
    else { println('Service status: ${status}') }
}

// Get detailed status information
detailed_status := service.status_detailed()!
println(detailed_status)
```

## Log Management

### Basic Log Retrieval

```v
// Get last 100 lines
logs := service.get_logs(100)!

// Using journalctl directly
logs := systemd.journalctl(service: 'my_service', limit: 50)!
```

### Advanced Log Filtering

```v
// Get error logs only
error_logs := systemd.journalctl_errors('my_service')!

// Get logs since specific time
recent_logs := systemd.journalctl_recent('my_service', '1 hour ago')!

// Custom log filtering
filtered_logs := systemd.journalctl(
    service: 'my_service'
    since: '2024-01-01'
    priority: 'warning'
    grep: 'connection'
    limit: 200
)!
```

## Health Monitoring

### Individual Service Health Check

```v
is_healthy := systemd.validate_service('my_service')!
if !is_healthy {
    println('Service needs attention')
}
```

### System-wide Health Check

```v
health_results := systemd.health_check()!
for service_name, is_healthy in health_results {
    if !is_healthy {
        println('Service ${service_name} is not healthy')
    }
}
```

## Error Handling

The module provides detailed error messages with log context:

```v
// Service creation with error handling
mut service := systemd.new(
    name: 'problematic_service'
    cmd: '/nonexistent/binary'
    start: true
) or {
    println('Failed to create service: ${err}')
    // Error will include recent logs showing why service failed
    return
}
```

## Service Deletion

```v
// Stop and remove service completely
service.delete()!

// Or using systemd factory
systemd.destroy('service_name')!
```

## Best Practices

1. **Always handle errors**: Service operations can fail, always use `!` or `or` blocks
2. **Use descriptive names**: Service names should be clear and unique
3. **Check logs on failure**: When services fail, check logs for diagnostic information
4. **Validate service health**: Regularly check service status in production
5. **Use environment variables**: Keep configuration flexible with environment variables

## Common Patterns

### Conditional Service Creation

```v
if !systemd.exists('my_service') {
    mut service := systemd.new(
        name: 'my_service'
        cmd: 'my_application'
        start: true
    )!
}
```

### Service with Dependency

```v
// Ensure dependency is running first
redis_status := systemd.get('redis')!.status()!
if redis_status != .active {
    return error('Redis must be running before starting web service')
}

mut web_service := systemd.new(
    name: 'web_service'
    cmd: 'web_server --redis-host localhost:6379'
    start: true
)!
```

## Troubleshooting

### Service Won't Start

1. Check service logs: `service.get_logs(100)!`
2. Verify command exists: `osal.cmd_exists('your_command')`
3. Check file permissions and paths
4. Review systemd unit file: `cat /etc/systemd/system/service_name.service`

### Service Keeps Failing

1. Get error logs: `systemd.journalctl_errors('service_name')!`
2. Check if command is executable
3. Verify environment variables and working directory
4. Test command manually: `your_command_here`

## Testing

```v
// Test module
vtest ~/code/github/incubaid/herolib/lib/osal/systemd/systemd_process_test.v