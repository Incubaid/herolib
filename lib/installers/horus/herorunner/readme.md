# Herorunner Installer

A V language installer module for building and managing the Hero Runner service. This installer handles the complete lifecycle of the Herorunner binary from the Horus workspace.

## Features

- **Automatic Rust Installation**: Installs Rust toolchain if not present
- **Git Repository Management**: Clones and manages the horus repository
- **Binary Building**: Compiles the herorunner binary from the horus workspace
- **Service Management**: Start/stop/restart via zinit
- **Configuration**: Customizable Redis connection

## Quick Start

### Manual Usage

```v
import freeflowuniverse.herolib.installers.horus.herorunner as herorunner_installer

mut herorunner := herorunner_installer.get()!
herorunner.install()!
herorunner.start()!
```

## Configuration

```bash
!!herorunner.configure
    name:'default'
    binary_path:'/hero/var/bin/herorunner'
    redis_addr:'127.0.0.1:6379'
    log_level:'info'
    repo_path:'/root/code/git.ourworld.tf/herocode/horus'
```

### Configuration Fields

- **name**: Instance name (default: 'default')
- **binary_path**: Path where the herorunner binary will be installed (default: '/hero/var/bin/herorunner')
- **redis_addr**: Redis server address (default: '127.0.0.1:6379')
- **log_level**: Rust log level - trace, debug, info, warn, error (default: 'info')
- **repo_path**: Path to clone the horus repository (default: '/root/code/git.ourworld.tf/herocode/horus')

## Commands

### Install
Builds the herorunner binary from the horus workspace. This will:
1. Install Rust if not present
2. Clone the horus repository from git.ourworld.tf
3. Build the herorunner binary with `cargo build -p runner-hero --release`

```bash
hero herorunner.install
```

### Start
Starts the herorunner service using zinit:

```bash
hero herorunner.start
```

### Stop
Stops the running service:

```bash
hero herorunner.stop
```

### Restart
Restarts the service:

```bash
hero herorunner.restart
```

### Destroy
Stops the service and removes all files:

```bash
hero herorunner.destroy
```

## Requirements

- **Dependencies**: 
  - Rust toolchain (automatically installed)
  - Git (for cloning repository)
  - Redis (must be running separately)

## Architecture

The installer follows the standard herolib installer pattern:

- **herorunner_model.v**: Configuration structure and initialization
- **herorunner_actions.v**: Build, install, start, stop, destroy logic
- **herorunner_factory_.v**: Factory pattern for instance management

## Notes

- The installer builds from source rather than downloading pre-built binaries
- Redis must be running and accessible at the configured address
- The binary is built with `RUSTFLAGS="-A warnings"` to suppress warnings
- Service management uses zinit by default
