| RPC Call | Example In | Example Out | 1-Sentence Description |
|---------|-----------|------------|------------------------|
| `rpc.discover` | `{}` | `{ "openrpc": "1.2.6", "info": { "version": "1.0.0", "title": "Zinit JSON-RPC API" } }` | Returns the full OpenRPC specification of the Zinit API. |
| `service_list` | `{}` | `{ "service1": "Running", "service2": "Success", "service3": "Error" }` | Lists all managed services and their current states. |
| `service_status` | `{ "name": "redis" }` | `{ "name": "redis", "pid": 1234, "state": "Running", "target": "Up", "after": { "dependency1": "Success", "dependency2": "Running" } }` | Returns detailed status including PID, state, dependencies, and target. |
| `service_start` | `{ "name": "redis" }` | `null` | Starts a specified service; returns no result on success. |
| `service_stop` | `{ "name": "redis" }` | `null` | Stops a specified service; returns no result on success. |
| `service_monitor` | `{ "name": "redis" }` | `null` | Starts monitoring a service using its configuration from the config directory. |
| `service_forget` | `{ "name": "redis" }` | `null` | Stops monitoring a service; only allowed for stopped services. |
| `service_kill` | `{ "name": "redis", "signal": "SIGTERM" }` | `null` | Sends a signal (e.g., SIGTERM) to a running service. |
| `system_shutdown` | `{}` | `null` | Stops all services and powers off the system. |
| `system_reboot` | `{}` | `null` | Stops all services and reboots the system. |
| `service_create` | `{ "name": "redis", "content": { "exec": "redis-server", "oneshot": false, "after": ["network"], "log": "stdout", "env": { "REDIS_PASSWORD": "secret" }, "shutdown_timeout": 30 } }` | `"service_config/redis"` | Creates a new service configuration file with specified settings. |
| `service_delete` | `{ "name": "redis" }` | `"service deleted"` | Deletes a service configuration file. |
| `service_get` | `{ "name": "redis" }` | `{ "exec": "redis-server", "oneshot": false, "after": ["network"] }` | Retrieves the configuration content of a service. |
| `service_stats` | `{ "name": "redis" }` | `{ "name": "redis", "pid": 1234, "memory_usage": 10485760, "cpu_usage": 2.5, "children": [ { "pid": 1235, "memory_usage": 5242880, "cpu_usage": 1.2 } ] }` | Returns memory and CPU usage statistics for a running service. |
| `system_start_http_server` | `{ "address": "127.0.0.1:8080" }` | `"HTTP server started at 127.0.0.1:8080"` | Starts an HTTP/RPC server on the specified network address. |
| `system_stop_http_server` | `{}` | `null` | Stops the currently running HTTP/RPC server. |
| `stream_currentLogs` | `{ "name": "redis" }` | `["2023-01-01T12:00:00 redis: Starting service", "2023-01-01T12:00:02 redis: Service started"]` | Returns current logs; optionally filtered by service name. |
| `stream_subscribeLogs` | `{ "name": "redis" }` | `"2023-01-01T12:00:00 redis: Service started"` | Subscribes to real-time log messages, optionally filtered by service. |
