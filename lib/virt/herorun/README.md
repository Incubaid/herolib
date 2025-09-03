# HeroRun - Remote Container Management

A V library for managing remote containers using runc and tmux, with support for multiple cloud providers.

## Features

- **Multi-provider support**: Currently supports Hetzner, with ThreeFold coming soon
- **Automatic setup**: Installs required packages (runc, tmux, curl, xz-utils) automatically
- **Container isolation**: Uses runc for lightweight container management
- **tmux integration**: Each container gets its own tmux session for multiple concurrent shells
- **Clean API**: Simple interface that hides infrastructure complexity

## Project Structure

```txt
lib/virt/herorun/
├── interfaces.v          # Shared interfaces and parameter structs
├── nodes.v               # Node management and SSH connectivity
├── container.v           # Container struct and lifecycle operations
├── executor.v            # Optimized command execution engine
├── factory.v             # Provider abstraction and backend creation
├── hetzner_backend.v     # Hetzner cloud implementation
└── README.md            # This file
```

## Usage

### Basic Example

```v
import freeflowuniverse.herolib.virt.herorun

fn main() {
    // Create user with SSH key
    mut user := herorun.new_user(keyname: 'id_ed25519')!
    
    // Create Hetzner backend
    mut backend := herorun.new_hetzner_backend(
        node_ip: '65.21.132.119'
        user:    'root'
    )!

    // Connect to node (installs required packages automatically)
    backend.connect(keyname: user.keyname)!
    
    // Send a test command to the node
    backend.send_command(cmd: 'ls')!

    // Get or create container (uses tmux behind the scenes)
    mut container := backend.get_or_create_container(name: 'test_container')!
    
    // Attach to container tmux session
    container.attach()!

    // Send command to container
    container.send_command(cmd: 'ls')!
    
    // Get container logs
    logs := container.get_logs()!
    println('Container logs:')
    println(logs)
}
```

### Running the Example

```bash
# Make the example executable
chmod +x examples/virt/herorun/herorun.vsh

# Run it
./examples/virt/herorun/herorun.vsh
```

## Architecture

### Interfaces

- **NodeBackend**: Defines operations for connecting to and managing remote nodes
- **ContainerBackend**: Defines operations for container lifecycle management

### Providers

- **HetznerBackend**: Implementation for Hetzner cloud servers
- **ThreeFoldBackend**: (Coming soon) Implementation for ThreeFold nodes

### Key Components

1. **SSH Integration**: Uses herolib's sshagent module for secure connections
2. **tmux Management**: Uses herolib's tmux module for session management
3. **Container Runtime**: Uses runc for lightweight container execution
4. **Hetzner Integration**: Uses herolib's hetznermanager module

## Dependencies

- `freeflowuniverse.herolib.osal.sshagent`
- `freeflowuniverse.herolib.osal.tmux`
- `freeflowuniverse.herolib.installers.web.hetznermanager`
- `freeflowuniverse.herolib.ui.console`

## Future Enhancements

- ThreeFold backend implementation
- Support for additional cloud providers (AWS, GCP, etc.)
- Container image management
- Network configuration
- Volume mounting
- Resource limits and monitoring
