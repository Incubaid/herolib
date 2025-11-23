# Redis Installer

A modular Redis installer that works across multiple platforms (Ubuntu, Debian, Alpine, Arch, macOS, containers).

## Features

- Cross-platform support (systemd and non-systemd systems)
- Automatic package installation via package managers
- Configurable data directory, port, and IP address
- Smart startup (uses systemctl when available, falls back to direct start)
- No circular dependencies (works without Redis being pre-installed)

## Quick Start

### Simple Installation

```v
import incubaid.herolib.installers.base.redis

// Create configuration
config := redis.RedisInstall{
    port: 6379
    datadir: '/var/lib/redis'
    ipaddr: 'localhost'
}

// Install and start Redis
redis.redis_install(config)!

// Check if running
if redis.check(config) {
    println('Redis is running!')
}
```

### Using Individual Functions

```v
import incubaid.herolib.installers.base.redis

config := redis.RedisInstall{
    port: 6379
    datadir: '/var/lib/redis'
    ipaddr: 'localhost'
}

// Install package only (doesn't start)
redis.redis_install(config)!

// Start Redis
redis.start(config)!

// Stop Redis
redis.stop()!

// Restart Redis
redis.restart(config)!

// Check if running
is_running := redis.check(config)
```

## Configuration Options

```v
pub struct RedisInstall {
pub mut:
    name    string = 'default'      // Instance name
    port    int    = 6379           // Redis port
    datadir string = '/var/lib/redis' // Data directory
    ipaddr  string = 'localhost'    // Bind address (space-separated for multiple)
}
```

## Platform Support

| Platform | Package Manager | Startup Method |
|----------|----------------|----------------|
| Ubuntu/Debian | apt (redis-server) | systemctl |
| Alpine | apk (redis) | direct start |
| Arch | pacman (redis) | systemctl |
| Fedora | dnf (redis) | systemctl |
| macOS | brew (redis) | direct start |
| Containers | varies | direct start |

## Using with Factory (Advanced)

For applications that need Redis state management:

```v
import incubaid.herolib.installers.base.redis

// Create and store in factory
mut installer := redis.new(name: 'myredis')!

// Install and start
installer.install(reset: false)!
installer.start()!

// Check status
if installer.running()! {
    println('Redis is running')
}

// Stop
installer.stop()!
```

## Example Script

See `examples/installers/base/redis.vsh` for a complete working example.

## Notes

- Default data directory is `/var/lib/redis` (standard location)
- On systemd systems, uses the package's systemd service
- On non-systemd systems, starts Redis directly with `--daemonize yes`
- Automatically handles permissions for the Redis user
- Config file location: `/etc/redis/redis.conf` (Linux) or `${datadir}/redis.conf` (macOS)
