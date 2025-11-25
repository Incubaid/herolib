# HeroPods

HeroPods is a lightweight container management system built on crun (OCI runtime), providing Docker-like functionality with bridge networking, automatic IP allocation, and image management via Podman.

## Requirements

**Platform:** Linux only

HeroPods requires Linux-specific tools and will not work on macOS or Windows:

- `crun` (OCI runtime)
- `ip` (iproute2 package)
- `iptables` (for NAT)
- `nsenter` (for network namespace management)
- `podman` (optional, for image management)

On macOS/Windows, please use Docker or Podman directly instead of HeroPods.

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
// Use keep_alive for containers with short-lived entrypoints
container.start(keep_alive: true)!

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

container.start(keep_alive: true)!
```

### Using HeroScript

```heroscript
!!heropods.configure
    name:'my_heropods'
    reset:false
    use_podman:true

!!heropods.container_new
    name:'my_container'
    image:'custom'
    custom_image_name:'alpine_3_20'
    docker_url:'docker.io/library/alpine:3.20'

!!heropods.container_start
    name:'my_container'
    keep_alive:true

!!heropods.container_exec
    name:'my_container'
    cmd:'echo "Hello from HeroPods!"'
    stdout:true

!!heropods.container_stop
    name:'my_container'

!!heropods.container_delete
    name:'my_container'
```

### Mycelium IPv6 Overlay Network

HeroPods supports Mycelium for end-to-end encrypted IPv6 connectivity:

```heroscript
!!heropods.configure
    name:'mycelium_demo'
    reset:false
    use_podman:true

!!heropods.enable_mycelium
    heropods:'mycelium_demo'
    version:'v0.5.6'
    ipv6_range:'400::/7'
    key_path:'~/hero/cfg/priv_key.bin'
    peers:'tcp://185.69.166.8:9651,quic://[2a02:1802:5e:0:ec4:7aff:fe51:e36b]:9651'

!!heropods.container_new
    name:'ipv6_container'
    image:'alpine_3_20'

!!heropods.container_start
    name:'ipv6_container'
    keep_alive:true

// Container now has both IPv4 and IPv6 (Mycelium) connectivity
```

See [MYCELIUM.md](./MYCELIUM.md) for detailed Mycelium configuration.

### Keep-Alive Feature

The `keep_alive` parameter keeps containers running after their entrypoint exits successfully. This is useful for:

- **Short-lived entrypoints**: Containers whose entrypoint performs initialization then exits (e.g., Alpine's `/bin/sh`)
- **Interactive containers**: Containers you want to exec into after startup
- **Service containers**: Containers that need to stay alive for background tasks

**How it works**:
1. Container starts with its original ENTRYPOINT and CMD (OCI-compliant)
2. HeroPods waits for the entrypoint to complete
3. If entrypoint exits with code 0 (success), a keep-alive process is injected
4. If entrypoint fails (non-zero exit), container stops and error is returned

**Example**:
```v
// Alpine's default CMD is /bin/sh which exits immediately
mut container := hp.container_new(
    name:              'my_alpine'
    image:             .custom
    custom_image_name: 'alpine_3_20'
    docker_url:        'docker.io/library/alpine:3.20'
)!

// Without keep_alive: container would exit immediately
// With keep_alive: container stays running for exec commands
container.start(keep_alive: true)!

// Now you can exec into the container
result := container.exec(cmd: 'echo "Hello!"')!
```

**Note**: If you see a warning about "bare shell CMD", use `keep_alive: true` when starting the container.

## Features

- **Container Lifecycle**: create, start, stop, delete, exec
- **Keep-Alive Support**: Keep containers running after entrypoint exits
- **IPv4 Bridge Networking**: Automatic IP allocation with NAT
- **IPv6 Mycelium Overlay**: End-to-end encrypted peer-to-peer networking
- **Image Management**: Pull Docker images via Podman or use built-in images
- **Resource Monitoring**: CPU and memory usage tracking
- **Thread-Safe**: Concurrent container operations supported
- **Configurable**: Custom network settings, DNS, resource limits

## Examples

See `examples/virt/heropods/` for complete working examples:

### HeroScript Examples

- **simple_container.heroscript** - Basic container lifecycle management
- **ipv4_connection.heroscript** - IPv4 networking and internet connectivity
- **container_mycelium.heroscript** - Mycelium IPv6 overlay networking

### V Language Examples

- **heropods.vsh** - Complete API demonstration
- **runcommands.vsh** - Simple command execution

Each example is fully documented and can be run independently. See [examples/virt/heropods/README.md](../../../examples/virt/heropods/README.md) for details.

## Documentation

- **[MYCELIUM.md](./MYCELIUM.md)** - Mycelium IPv6 overlay network integration guide
- **[PRODUCTION_READINESS_REVIEW.md](./PRODUCTION_READINESS_REVIEW.md)** - Production readiness assessment
- **[ACTIONABLE_RECOMMENDATIONS.md](./ACTIONABLE_RECOMMENDATIONS.md)** - Code quality recommendations
