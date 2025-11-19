# Mycelium IPv6 Overlay Network Integration for HeroPods

## Prerequisites

**Mycelium must be installed on your system before using this feature.** HeroPods does not install Mycelium automatically.

### Installing Mycelium

Download and install Mycelium from the official repository:

- **GitHub**: <https://github.com/threefoldtech/mycelium>
- **Releases**: <https://github.com/threefoldtech/mycelium/releases>

For detailed installation instructions, see the [Mycelium documentation](https://github.com/threefoldtech/mycelium/tree/master/docs).

After installation, verify that the `mycelium` command is available:

```bash
mycelium -V
```

## Overview

HeroPods now supports Mycelium IPv6 overlay networking, providing end-to-end encrypted IPv6 connectivity for containers across the internet.

## What is Mycelium?

Mycelium is an IPv6 overlay network that provides:

- **End-to-end encrypted** connectivity in the `400::/7` address range
- **Peer-to-peer routing** through public relay nodes
- **Automatic address assignment** based on cryptographic keys
- **NAT traversal** for containers behind firewalls

## Architecture

### Components

1. **mycelium.v** - Core Mycelium integration logic
   - Service management (start/stop)
   - Container IPv6 configuration
   - veth pair creation for IPv6 routing

2. **heropods_model.v** - Configuration struct
   - `MyceliumConfig` struct with enable flag, peers, key path

3. **container.v** - Lifecycle integration
   - Mycelium setup during container start
   - Mycelium cleanup during container stop/delete

### How It Works

1. **Host Setup**:
   - Mycelium service runs on the host
   - Connects to public peer nodes for routing
   - Gets a unique IPv6 address in `400::/7` range

2. **Container Setup**:
   - Creates a veth pair (`vmy-HASH` ↔ `vmyh-HASH`)
   - Assigns container IPv6 from host's `/64` prefix
   - Configures routing through host's Mycelium interface

3. **Connectivity**:
   - Container can reach other Mycelium nodes via IPv6
   - Traffic is encrypted end-to-end
   - Works across NAT and firewalls

## Configuration

### Enable Mycelium

All parameters are **required** when enabling Mycelium:

```heroscript
!!heropods.configure
    name:'demo'

!!heropods.enable_mycelium
    heropods:'demo'
    version:'v0.5.6'
    ipv6_range:'400::/7'
    key_path:'~/hero/cfg/priv_key.bin'
    peers:'tcp://185.69.166.8:9651,quic://[2a02:1802:5e:0:ec4:7aff:fe51:e36b]:9651,tcp://65.109.18.113:9651'
```

### Configuration Parameters

All parameters are **required**:

- `version` (string): Mycelium version to install (e.g., 'v0.5.6')
- `ipv6_range` (string): Mycelium IPv6 address range (e.g., '400::/7')
- `key_path` (string): Path to Mycelium private key (e.g., '~/hero/cfg/priv_key.bin')
- `peers` (string): Comma-separated list of Mycelium peer addresses (e.g., 'tcp://185.69.166.8:9651,quic://[2a02:1802:5e:0:ec4:7aff:fe51:e36b]:9651')

### Default Public Peers

You can use these public Mycelium peers:

```text
tcp://185.69.166.8:9651
quic://[2a02:1802:5e:0:ec4:7aff:fe51:e36b]:9651
tcp://65.109.18.113:9651
quic://[2a01:4f9:5a:1042::2]:9651
tcp://5.78.122.16:9651
quic://[2a01:4ff:1f0:8859::1]:9651
tcp://5.223.43.251:9651
quic://[2a01:4ff:2f0:3621::1]:9651
tcp://142.93.217.194:9651
quic://[2400:6180:100:d0::841:2001]:9651
```

## Usage Example

See `examples/virt/heropods/container_mycelium.heroscript` for a complete example:

**Basic example:**

```heroscript
// Configure HeroPods
!!heropods.configure
    name:'mycelium_demo'

// Enable Mycelium with all required parameters
!!heropods.enable_mycelium
    heropods:'mycelium_demo'
    version:'v0.5.6'
    ipv6_range:'400::/7'
    key_path:'~/hero/cfg/priv_key.bin'
    peers:'tcp://185.69.166.8:9651,quic://[2a02:1802:5e:0:ec4:7aff:fe51:e36b]:9651'

// Create and start container
!!heropods.container_new
    name:'my_container'
    image:'alpine_3_20'

!!heropods.container_start
    name:'my_container'

// Test Mycelium connectivity
!!heropods.container_exec
    name:'my_container'
    cmd:'ip -6 addr show'
    stdout:true
```

**Run the complete example:**

```bash
hero run examples/virt/heropods/container_mycelium.heroscript
```

## Network Details

### IPv6 Address Assignment

- Host gets address like: `400:1234:5678::1`
- Container gets address like: `400:1234:5678::2`
- Uses `/64` prefix from host's Mycelium address

### Routing

- Container → Host: via veth pair link-local addresses
- Host → Mycelium network: via Mycelium TUN interface
- End-to-end encryption handled by Mycelium

### Interface Names

- Container side: `vmy-HASH` (6-char hash of container name)
- Host side: `vmyh-HASH`
- Mycelium TUN: `mycelium0` (configurable)

## Troubleshooting

### Check Mycelium Status

```bash
mycelium inspect --key-file ~/hero/cfg/priv_key.bin --json
```

### Verify Container IPv6

```bash
# Inside container
ip -6 addr show
ip -6 route show
```

### Test Connectivity

```bash
# Ping a public Mycelium node
ping6 -c 3 400:8f3a:8d0e:3503:db8e:6a02:2e9:83dd
```

### Common Issues

1. **Mycelium service not running**: Check with `ps aux | grep mycelium`
2. **No IPv6 connectivity**: Verify IPv6 forwarding is enabled: `sysctl net.ipv6.conf.all.forwarding`
3. **Container can't reach Mycelium network**: Check routes with `ip -6 route show`

## Security

- All Mycelium traffic is end-to-end encrypted
- Each node has a unique cryptographic identity
- Private key stored at `~/hero/cfg/priv_key.bin` (configurable)
- Container inherits host's Mycelium identity

## Performance

- Minimal overhead for local routing
- Peer-to-peer routing for optimal paths
- Automatic failover between peer nodes

## Future Enhancements

- Per-container Mycelium identities
- Custom routing policies
- IPv6 firewall rules
- Mycelium network isolation
