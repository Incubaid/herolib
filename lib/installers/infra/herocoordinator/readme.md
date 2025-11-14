# Herocoordinator Installer

A V language installer module for building and managing the Herocoordinator service. This installer handles the complete lifecycle of the Herocoordinator binary from the Horus workspace.

## Features

- **Automatic Rust Installation**: Installs Rust toolchain if not present
- **Git Repository Management**: Clones and manages the horus repository
- **Binary Building**: Compiles the coordinator binary from the horus workspace
- **Service Management**: Start/stop/restart via zinit
- **Configuration**: Customizable Redis, HTTP, and WebSocket ports

## Quick Start

### Using the Example Script

```bash
cd /root/code/github/incubaid/herolib/examples/installers/infra
./herocoordinator.vsh
```

### Manual Usage

```v
import incubaid.herolib.installers.infra.herocoordinator as herocoordinator_installer

mut herocoordinator := herocoordinator_installer.get()!
herocoordinator.install()!
herocoordinator.start()!
```

## Configuration

```bash
!!herocoordinator.configure
    name:'default'
    binary_path:'/hero/var/bin/coordinator'
    redis_addr:'127.0.0.1:6379'
    http_port:8081
    ws_port:9653
    log_level:'info'
    repo_path:'/root/code/git.ourworld.tf/herocode/horus'
```

### Configuration Fields

- **name**: Instance name (default: 'default')
- **binary_path**: Path where the coordinator binary will be installed (default: '/hero/var/bin/coordinator')
- **redis_addr**: Redis server address (default: '127.0.0.1:6379')
- **http_port**: HTTP API port (default: 8081)
- **ws_port**: WebSocket API port (default: 9653)
- **log_level**: Rust log level - trace, debug, info, warn, error (default: 'info')
- **repo_path**: Path to clone the horus repository (default: '/root/code/git.ourworld.tf/herocode/horus')

## Commands

### Install
Builds the coordinator binary from the horus workspace. This will:
1. Install Rust if not present
2. Clone the horus repository from git.ourworld.tf
3. Build the coordinator binary with `cargo build -p hero-coordinator --release`

```bash
hero herocoordinator.install
```

### Start
Starts the herocoordinator service using zinit:

```bash
hero herocoordinator.start
```

### Stop
Stops the running service:

```bash
hero herocoordinator.stop
```

### Restart
Restarts the service:

```bash
hero herocoordinator.restart
```

### Destroy
Stops the service and removes all files:

```bash
hero herocoordinator.destroy
```

## Requirements

- **Dependencies**: 
  - Rust toolchain (automatically installed)
  - Git (for cloning repository)
  - Redis (must be running separately)
  - Mycelium (must be installed and running separately)

## Architecture

The installer follows the standard herolib installer pattern:

- **herocoordinator_model.v**: Configuration structure and initialization
- **herocoordinator_actions.v**: Build, install, start, stop, destroy logic
- **herocoordinator_factory_.v**: Factory pattern for instance management

## Notes

- The installer builds from source rather than downloading pre-built binaries
- Mycelium is expected to be already installed and running in the environment
- Redis must be running and accessible at the configured address
- The binary is built with `RUSTFLAGS="-A warnings"` to suppress warnings
- Service management uses zinit by default

## Example Workflow

```v
import incubaid.herolib.installers.infra.herocoordinator as hc

// Get installer instance
mut coordinator := hc.get()!

// Customize configuration
coordinator.redis_addr = '127.0.0.1:6379'
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
