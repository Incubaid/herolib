# HeroPods

HeroPods is a lightweight container management system built on crun (OCI runtime), providing Docker-like functionality with bridge networking, automatic IP allocation, and image management via Podman.

## Quick Start

### Basic Usage

```v
import incubaid.herolib.virt.heropods

// Initialize HeroPods
mut hp := heropods.new(
    reset:      false
    use_podman: true
)!

// Create a container (definition only, not yet created in backend)
mut container := hp.container_new(
    name:              'my_alpine'
    image:             .custom
    custom_image_name: 'alpine_3_20'
    docker_url:        'docker.io/library/alpine:3.20'
)!

// Start the container (creates and starts it)
container.start()!

// Execute commands
result := container.exec(cmd: 'ls -la /')!
println(result)

// Stop and delete
container.stop()!
container.delete()!
```

### Custom Network Configuration

Configure bridge name, subnet, gateway, and DNS servers:

```v
import incubaid.herolib.virt.heropods

// Initialize with custom network settings
mut hp := heropods.new(
    reset:       false
    use_podman:  true
    bridge_name: 'mybr0'
    subnet:      '192.168.100.0/24'
    gateway_ip:  '192.168.100.1'
    dns_servers: ['1.1.1.1', '1.0.0.1']
)!

// Containers will use the custom network configuration
mut container := hp.container_new(
    name:              'custom_net_container'
    image:             .alpine_3_20
)!

container.start()!
```

### Using HeroScript

```heroscript
!!heropods.configure
    name:'demo'
    reset:false
    use_podman:true

!!heropods.container_new
    name:'demo_container'
    image:'custom'
    custom_image_name:'alpine_3_20'
    docker_url:'docker.io/library/alpine:3.20'

!!heropods.container_start
    name:'demo_container'

!!heropods.container_exec
    name:'demo_container'
    cmd:'echo "Hello from HeroPods!"'
    stdout:true

!!heropods.container_stop
    name:'demo_container'

!!heropods.container_delete
    name:'demo_container'
```

## Features

- **Container Lifecycle**: create, start, stop, delete, exec
- **Bridge Networking**: Automatic IP allocation with NAT
- **Image Management**: Pull Docker images via Podman or use built-in images
- **Resource Monitoring**: CPU and memory usage tracking
- **Thread-Safe**: Concurrent container operations supported
- **Configurable**: Custom network settings, DNS, resource limits

## More Examples

See `examples/virt/heropods/` for more detailed examples:

- `heropods.vsh` - Complete API demonstration
- `demo.heroscript` - HeroScript usage
- `runcommands.vsh` - Simple command execution

## Requirements

- **crun**: OCI container runtime (auto-installed if missing)
- **podman** (optional): For pulling Docker images
- **Linux**: Bridge networking requires Linux kernel features
