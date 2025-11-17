# Coordinator Installer

A V language installer module for building and managing the Coordinator service. This installer handles the complete lifecycle of the Coordinator binary from the Horus workspace.

## Features

- **Automatic Rust Installation**: Installs Rust toolchain if not present
- **Git Repository Management**: Clones and manages the horus repository
- **Binary Building**: Compiles the coordinator binary from the horus workspace
- **Service Management**: Start/stop/restart via zinit
- **Configuration**: Customizable Redis, HTTP, and WebSocket ports

## Quick Start

### Using the Example Script

```bash
cd /root/code/github/incubaid/herolib/examples/installers/horus
./coordinator.vsh
```

### Manual Usage

```v
import incubaid.herolib.installers.horus.coordinator as coordinator_installer

mut coordinator := coordinator_installer.get()!
coordinator.install()!
coordinator.start()!
```

## Configuration

```bash
!!coordinator.configure
    name:'default'
    binary_path:'/hero/var/bin/coordinator'
    redis_addr:'127.0.0.1:6379'
    redis_port:6379
    http_port:8081
    ws_port:9653
    log_level:'info'
    repo_path:'/root/code/git.ourworld.tf/herocode/horus'
```

### Configuration Fields

- **name**: Instance name (default: 'default')
- **binary_path**: Path where the coordinator binary will be installed (default: '/hero/var/bin/coordinator')
- **redis_addr**: Redis server address (default: '127.0.0.1:6379')
- **redis_port**: Redis server port (default: 6379)
- **http_port**: HTTP API port (default: 8081)
- **ws_port**: WebSocket API port (default: 9653)
- **log_level**: Rust log level - trace, debug, info, warn, error (default: 'info')
- **repo_path**: Path to clone the horus repository (default: '/root/code/git.ourworld.tf/herocode/horus')

## Commands

### Install
Builds the coordinator binary from the horus workspace. This will:
1. Check if Rust is installed (installs if not present)
2. Clone the horus repository from git.ourworld.tf
3. Build the coordinator binary with `cargo build -p hero-coordinator --release`

**Note**: The installer skips the build if the binary already exists at the configured path.

```bash
hero coordinator.install
```

### Force Reinstall
To force a rebuild even if the binary already exists, use the `reset` flag:

```v
import incubaid.herolib.installers.horus.coordinator as coordinator_installer

mut coordinator := coordinator_installer.get()!
coordinator.install(reset: true)!  // Force reinstall
```

Or manually delete the binary before running install:

```bash
rm /hero/var/bin/coordinator
hero coordinator.install
```

### Start
Starts the coordinator service using zinit:

```bash
hero coordinator.start
```

### Stop
Stops the running service:

```bash
hero coordinator.stop
```

### Restart
Restarts the service:

```bash
hero coordinator.restart
```

### Destroy
Stops the service and removes all files:

```bash
hero coordinator.destroy
```

## Requirements

- **Dependencies**: 
  - Rust toolchain (automatically installed if not present)
  - Git (for cloning repository)
  - Redis (must be pre-installed and running)
  - Mycelium (must be installed and running separately)

## Architecture

The installer follows the standard herolib installer pattern:

- **coordinator_model.v**: Configuration structure and initialization
- **coordinator_actions.v**: Build, install, start, stop, destroy logic
- **coordinator_factory_.v**: Factory pattern for instance management

## Notes

- The installer builds from source rather than downloading pre-built binaries
- **Redis must be pre-installed and running** - the installer does not install Redis
- The installer checks if the binary already exists and skips rebuild unless `reset: true` is used
- Rust is automatically installed if not present (checks for `rustc` command)
- The binary is built with `RUSTFLAGS="-A warnings"` to suppress warnings
- Service management uses zinit by default

## Example Workflow

```v
import incubaid.herolib.installers.horus.coordinator as hc

// Get installer instance
mut coordinator := hc.get()!

// Customize configuration
coordinator.redis_addr = '127.0.0.1:6379'
coordinator.redis_port = 6379
coordinator.http_port = 8081
coordinator.log_level = 'debug'
hc.set(coordinator)!

// Build and start
coordinator.install()!
coordinator.start()!

// Check status
if coordinator.running()! {
    println('Coordinator is running on port ${coordinator.http_port}')
}

// Later: cleanup
coordinator.destroy()!
