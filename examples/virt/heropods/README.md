# HeroPods Examples

This directory contains example HeroScript files demonstrating different HeroPods use cases.

## Prerequisites

- **Linux system** (HeroPods requires Linux-specific tools: ip, iptables, nsenter, crun)
- **Root/sudo access** (required for network configuration and container management)
- **Podman** (optional but recommended for image management)
- **Hero CLI** installed and configured

## Example Scripts

### 1. simple_container.heroscript

**Purpose**: Demonstrate basic container lifecycle management

**What it does**:

- Creates a HeroPods instance
- Creates an Alpine Linux container
- Starts the container
- Executes basic commands inside the container (uname, ls, cat, ps, env)
- Stops the container
- Deletes the container

**Run it**:

```bash
hero run examples/virt/heropods/simple_container.heroscript
```

**Use this when**: You want to learn the basic container operations without networking complexity.

---

### 2. ipv4_connection.heroscript

**Purpose**: Demonstrate IPv4 networking and internet connectivity

**What it does**:

- Creates a HeroPods instance with bridge networking
- Creates an Alpine Linux container
- Starts the container with IPv4 networking
- Verifies network configuration (interfaces, routes, DNS)
- Tests DNS resolution
- Tests HTTP/HTTPS connectivity to the internet
- Stops and deletes the container

**Run it**:

```bash
hero run examples/virt/heropods/ipv4_connection.heroscript
```

**Use this when**: You want to verify that IPv4 bridge networking and internet access work correctly.

---

### 3. container_mycelium.heroscript

**Purpose**: Demonstrate Mycelium IPv6 overlay networking

**What it does**:

- Creates a HeroPods instance
- Enables Mycelium IPv6 overlay network with all required configuration
- Creates an Alpine Linux container
- Starts the container with both IPv4 and IPv6 (Mycelium) networking
- Verifies IPv6 configuration
- Tests Mycelium IPv6 connectivity to public nodes
- Verifies dual-stack networking (IPv4 + IPv6)
- Stops and deletes the container

**Run it**:

```bash
hero run examples/virt/heropods/container_mycelium.heroscript
```

**Use this when**: You want to test Mycelium IPv6 overlay networking for encrypted peer-to-peer connectivity.

**Note**: Requires Mycelium to be installed and configured on the host system.

---

### 4. demo.heroscript

**Purpose**: Quick demonstration of HeroPods with both IPv4 and IPv6 networking

**What it does**:

- Combines IPv4 and Mycelium IPv6 networking in a single demo
- Shows a complete workflow from configuration to cleanup
- Serves as a quick reference for common operations

**Run it**:

```bash
hero run examples/virt/heropods/demo.heroscript
```

**Use this when**: You want a quick overview of HeroPods capabilities.

---

## Common Issues

### Permission Denied for ping/ping6

Alpine Linux containers don't have `CAP_NET_RAW` capability by default, which is required for ICMP packets (ping).

**Solution**: Use `wget`, `curl`, or `nc` for connectivity testing instead of ping.

### Mycelium Not Found

If you get errors about Mycelium not being installed:

**Solution**: The HeroPods Mycelium integration will automatically install Mycelium when you run `heropods.enable_mycelium`. Make sure you have internet connectivity and the required permissions.

### Container Already Exists

If you get errors about containers already existing:

**Solution**: Either delete the existing container manually or set `reset:true` in the `heropods.configure` action.

---

## Learning Path

We recommend running the examples in this order:

1. **simple_container.heroscript** - Learn basic container operations
2. **ipv4_connection.heroscript** - Understand IPv4 networking
3. **container_mycelium.heroscript** - Explore IPv6 overlay networking
4. **demo.heroscript** - See everything together

---

## Customization

Feel free to modify these scripts to:

- Use different container images (Ubuntu, custom images, etc.)
- Test different network configurations
- Add your own commands and tests
- Experiment with multiple containers

---

## Documentation

For more information, see:

- [HeroPods Main README](../../../lib/virt/heropods/readme.md)
- [Mycelium Integration Guide](../../../lib/virt/heropods/MYCELIUM_README.md)
- [Production Readiness Review](../../../lib/virt/heropods/PRODUCTION_READINESS_REVIEW.md)

---

## Support

If you encounter issues:

1. Check the logs in `~/.containers/logs/`
2. Verify your system meets the prerequisites
3. Review the error messages carefully
4. Consult the documentation linked above
