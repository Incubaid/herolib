# Supervisor Installer

A V language installer module for building and managing the Supervisor service. This installer handles the complete lifecycle of the Supervisor binary from the Horus workspace.

## Features

- **Automatic Rust Installation**: Installs Rust toolchain if not present
- **Git Repository Management**: Clones and manages the horus repository
- **Binary Building**: Compiles the supervisor binary from the horus workspace
- **Service Management**: Start/stop/restart via zinit
- **Configuration**: Customizable Redis, HTTP, and WebSocket ports

## Quick Start

### Using the Example Script

```bash
cd /root/code/github/freeflowuniverse/herolib/examples/installers/horus
./supervisor.vsh
```

### Manual Usage

```v
import freeflowuniverse.herolib.installers.horus.supervisor as supervisor_installer

mut supervisor := supervisor_installer.get()!
supervisor.install()!
supervisor.start()!
```

## Configuration

```bash
!!supervisor.configure
    name:'default'
    binary_path:'/hero/var/bin/supervisor'
    redis_addr:'127.0.0.1:6379'
    http_port:8082
    ws_port:9654
    log_level:'info'
    repo_path:'/root/code/git.ourworld.tf/herocode/horus'
```

### Configuration Fields

- **name**: Instance name (default: 'default')
- **binary_path**: Path where the supervisor binary will be installed (default: '/hero/var/bin/supervisor')
- **redis_addr**: Redis server address (default: '127.0.0.1:6379')
- **http_port**: HTTP API port (default: 8082)
- **ws_port**: WebSocket API port (default: 9654)
- **log_level**: Rust log level - trace, debug, info, warn, error (default: 'info')
- **repo_path**: Path to clone the horus repository (default: '/root/code/git.ourworld.tf/herocode/horus')

## Commands

### Install
Builds the supervisor binary from the horus workspace. This will:
1. Install Rust if not present
2. Clone the horus repository from git.ourworld.tf
3. Build the supervisor binary with `cargo build -p hero-supervisor --release`

```bash
hero supervisor.install
```

### Start
Starts the supervisor service using zinit:

```bash
hero supervisor.start
```

### Stop
Stops the running service:

```bash
hero supervisor.stop
```

### Restart
Restarts the service:

```bash
hero supervisor.restart
```

### Destroy
Stops the service and removes all files:

```bash
hero supervisor.destroy
```

## Requirements

- **Dependencies**: 
  - Rust toolchain (automatically installed)
  - Git (for cloning repository)
  - Redis (must be running separately)
  - Mycelium (must be installed and running separately)

## Architecture

The installer follows the standard herolib installer pattern:

- **supervisor_model.v**: Configuration structure and initialization
- **supervisor_actions.v**: Build, install, start, stop, destroy logic
- **supervisor_factory_.v**: Factory pattern for instance management

## Notes

- The installer builds from source rather than downloading pre-built binaries
- Mycelium is expected to be already installed and running in the environment
- Redis must be running and accessible at the configured address
- The binary is built with `RUSTFLAGS="-A warnings"` to suppress warnings
- Service management uses zinit by default

## Example Workflow

```v
import freeflowuniverse.herolib.installers.horus.supervisor as sv

// Get installer instance
mut supervisor := sv.get()!

// Customize configuration
supervisor.redis_addr = '127.0.0.1:6379'
supervisor.http_port = 8082
supervisor.log_level = 'debug'
sv.set(supervisor)!

// Build and start
supervisor.install()!
supervisor.start()!

// Check status
if supervisor.running()! {
    println('Supervisor is running on port ${supervisor.http_port}')
}

// Later: cleanup
supervisor.destroy()!
```
