# Horus Installation Examples

This directory contains example scripts for installing and managing all Horus components using the herolib installer framework.

## Components

The Horus ecosystem consists of the following components:

1. **Coordinator** - Central coordination service (HTTP: 8081, WS: 9653)
2. **Supervisor** - Supervision and monitoring service (HTTP: 8082, WS: 9654)
3. **Hero Runner** - Command execution runner for Hero jobs
4. **Osiris Runner** - Database-backed runner
5. **SAL Runner** - System Abstraction Layer runner

## Quick Start

### Full Installation and Start

To install and start all Horus components:

```bash
# 1. Install all components (this will take several minutes)
./horus_full_install.vsh

# 2. Start all services
./horus_start_all.vsh

# 3. Check status
./horus_status.vsh
```

### Stop All Services

```bash
./horus_stop_all.vsh
```

## Available Scripts

### `horus_full_install.vsh`
Installs all Horus components:
- Checks and installs Redis if needed
- Checks and installs Rust if needed
- Clones the horus repository
- Builds all binaries from source

**Note:** This script can take 10-30 minutes depending on your system, as it compiles Rust code.

### `horus_start_all.vsh`
Starts all Horus services in the correct order:
1. Coordinator
2. Supervisor
3. Hero Runner
4. Osiris Runner
5. SAL Runner

### `horus_stop_all.vsh`
Stops all running Horus services in reverse order.

### `horus_status.vsh`
Checks and displays the status of all Horus services.

## Prerequisites

- **Operating System**: Linux or macOS
- **Dependencies** (automatically installed):
  - Redis (required for all components)
  - Rust toolchain (for building from source)
  - Git (for cloning repositories)

## Configuration

All components use default configurations:

### Coordinator
- Binary: `/hero/var/bin/coordinator`
- HTTP Port: `8081`
- WebSocket Port: `9653`
- Redis: `127.0.0.1:6379`

### Supervisor
- Binary: `/hero/var/bin/supervisor`
- HTTP Port: `8082`
- WebSocket Port: `9654`
- Redis: `127.0.0.1:6379`

### Runners
- Hero Runner: `/hero/var/bin/herorunner`
- Osiris Runner: `/hero/var/bin/runner_osiris`
- SAL Runner: `/hero/var/bin/runner_sal`

## Custom Configuration

To customize the configuration, you can use heroscript:

```v
import incubaid.herolib.installers.horus.coordinator

mut coordinator := herocoordinator.get(create: true)!
coordinator.http_port = 9000
coordinator.ws_port = 9001
coordinator.log_level = 'debug'
herocoordinator.set(coordinator)!
coordinator.install()!
coordinator.start()!
```

## Testing

After starting the services, you can test them:

```bash
# Test Coordinator HTTP endpoint
curl http://127.0.0.1:8081

# Test Supervisor HTTP endpoint
curl http://127.0.0.1:8082

# Check running processes
pgrep -f coordinator
pgrep -f supervisor
pgrep -f herorunner
pgrep -f runner_osiris
pgrep -f runner_sal
```

## Troubleshooting

### Redis Not Running
If you get Redis connection errors:
```bash
# Check if Redis is running
redis-cli ping

# Start Redis (Ubuntu/Debian)
sudo systemctl start redis-server

# Start Redis (macOS with Homebrew)
brew services start redis
```

### Build Failures
If the build fails:
1. Ensure you have enough disk space (at least 5GB free)
2. Check that Rust is properly installed: `rustc --version`
3. Try cleaning the build: `cd /root/code/git.ourworld.tf/herocode/horus && cargo clean`

### Port Conflicts
If ports 8081 or 8082 are already in use, you can customize the ports in the configuration.

## Advanced Usage

### Individual Component Installation

You can install components individually:

```bash
# Install only coordinator
v run coordinator_only.vsh

# Install only supervisor
v run supervisor_only.vsh
```

### Using with Heroscript

You can also use heroscript files for configuration:

```heroscript
!!herocoordinator.configure
    name:'production'
    http_port:8081
    ws_port:9653
    log_level:'info'

!!herocoordinator.install

!!herocoordinator.start
```

## Service Management

Services are managed using the system's startup manager (zinit or systemd):

```bash
# Check service status with systemd
systemctl status coordinator

# View logs
journalctl -u coordinator -f
```

## Cleanup

To completely remove all Horus components:

```bash
# Stop all services
./horus_stop_all.vsh

# Destroy all components (removes binaries)
v run horus_destroy_all.vsh
```

## Support

For issues or questions:
- Check the main Horus repository: https://git.ourworld.tf/herocode/horus
- Review the installer code in `lib/installers/horus/`
