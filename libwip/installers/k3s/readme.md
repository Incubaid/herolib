# K3s Installer

Complete K3s cluster installer with multi-master HA support, worker nodes, and Mycelium IPv6 networking.

## Features

- **Multi-Master HA**: Install multiple master nodes with `--cluster-init`
- **Worker Nodes**: Add worker nodes to the cluster
- **Mycelium IPv6**: Automatic detection of Mycelium IPv6 addresses from the 400::/7 range
- **Lifecycle Management**: Start, stop, restart K3s via startupmanager (systemd/zinit/screen)
- **Join Scripts**: Auto-generate heroscripts for joining additional nodes
- **Complete Cleanup**: Destroy removes all K3s components, network interfaces, and data

## Quick Start

### Install First Master

```v
import incubaid.herolib.installers.virt.k3s

heroscript := "
!!k3s.configure
    name:'k3s_master_1'
    k3s_version:'v1.33.1'
    node_name:'master-1'
    mycelium_interface:'mycelium0'

!!k3s.install_master name:'k3s_master_1'
!!k3s.start name:'k3s_master_1'
"

k3s.play(heroscript: heroscript)!
```

### Join Additional Master (HA)

```v
heroscript := "
!!k3s.configure
    name:'k3s_master_2'
    node_name:'master-2'
    token:'<TOKEN_FROM_FIRST_MASTER>'
    master_url:'https://[<MASTER_IPV6>]:6443'

!!k3s.join_master name:'k3s_master_2'
!!k3s.start name:'k3s_master_2'
"

k3s.play(heroscript: heroscript)!
```

### Install Worker Node

```v
heroscript := "
!!k3s.configure
    name:'k3s_worker_1'
    node_name:'worker-1'
    token:'<TOKEN_FROM_FIRST_MASTER>'
    master_url:'https://[<MASTER_IPV6>]:6443'

!!k3s.install_worker name:'k3s_worker_1'
!!k3s.start name:'k3s_worker_1'
"

k3s.play(heroscript: heroscript)!
```

## Configuration Options

| Field                | Type   | Default          | Description                                                |
| -------------------- | ------ | ---------------- | ---------------------------------------------------------- |
| `name`               | string | 'default'        | Instance name                                              |
| `k3s_version`        | string | 'v1.33.1'        | K3s version to install                                     |
| `data_dir`           | string | '~/hero/var/k3s' | Data directory for K3s                                     |
| `node_name`          | string | hostname         | Unique node identifier                                     |
| `mycelium_interface` | string | auto-detected    | Mycelium interface name (auto-detected from 400::/7 route) |
| `token`              | string | auto-generated   | Cluster authentication token                               |
| `master_url`         | string | -                | Master URL for joining (e.g., 'https://[ipv6]:6443')       |
| `node_ip`            | string | auto-detected    | Node IPv6 (auto-detected from Mycelium)                    |

## Actions

### Installation Actions

- `install_master` - Install first master node (generates token, uses --cluster-init)
- `join_master` - Join as additional master (requires token + master_url)
- `install_worker` - Install worker node (requires token + master_url)

### Lifecycle Actions

- `start` - Start K3s via startupmanager
- `stop` - Stop K3s
- `restart` - Restart K3s
- `destroy` - Complete cleanup (removes all K3s components)

### Utility Actions

- `get_kubeconfig` - Get kubeconfig content
- `generate_join_script` - Generate heroscript for joining nodes

## Requirements

- **OS**: Ubuntu (installer checks and fails on non-Ubuntu systems)
- **Mycelium**: Must be installed and running with interface in 400::/7 range
- **Root Access**: Required for installing system packages and managing network

## How It Works

### Mycelium IPv6 Detection

The installer automatically detects your Mycelium IPv6 address by:

1. Finding the 400::/7 route via the Mycelium interface
2. Extracting the next-hop IPv6 and getting the prefix (first 4 segments)
3. Matching global IPv6 addresses on the interface with the same prefix
4. Using the matched IPv6 for K3s `--node-ip`

This ensures K3s binds to the correct Mycelium IPv6 even if the server has other IPv6 addresses.

### Cluster Setup

**First Master:**

- Uses `--cluster-init` flag
- Auto-generates secure token
- Configures IPv6 CIDRs: cluster=2001:cafe:42::/56, service=2001:cafe:43::/112
- Generates join script for other nodes

**Additional Masters:**

- Joins with `--server <master_url>`
- Requires token and master_url from first master
- Provides HA for control plane

**Workers:**

- Joins as agent with `--server <master_url>`
- Requires token and master_url from first master

### Cleanup

The `destroy` action performs complete cleanup:

- Stops K3s process
- Removes network interfaces (cni0, flannel.*, etc.)
- Unmounts kubelet mounts
- Removes data directory
- Cleans up iptables/ip6tables rules
- Removes CNI namespaces

## Example Workflow

1. **Install first master on server1:**

   ```bash
   hero run templates/examples.heroscript
   # Note the token and IPv6 address displayed
   ```

2. **Join additional master on server2:**

   ```bash
   # Edit examples.heroscript Section 2 with token and master_url
   hero run templates/examples.heroscript
   ```

3. **Add worker on server3:**

   ```bash
   # Edit examples.heroscript Section 3 with token and master_url
   hero run templates/examples.heroscript
   ```

4. **Verify cluster:**

   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

## Kubeconfig

The kubeconfig is located at: `<data_dir>/server/cred/admin.kubeconfig`

To use kubectl:

```bash
export KUBECONFIG=~/hero/var/k3s/server/cred/admin.kubeconfig
kubectl get nodes
```

Or copy to default location:

```bash
mkdir -p ~/.kube
cp ~/hero/var/k3s/server/cred/admin.kubeconfig ~/.kube/config
```

## Troubleshooting

**K3s won't start:**

- Check if Mycelium is running: `ip -6 addr show mycelium0`
- Verify 400::/7 route exists: `ip -6 route | grep 400::/7`
- Check logs: `journalctl -u k3s_* -f`

**Can't join cluster:**

- Verify token matches first master
- Ensure master_url uses correct IPv6 in brackets: `https://[ipv6]:6443`
- Check network connectivity over Mycelium: `ping6 <master_ipv6>`

**Cleanup issues:**

- Run destroy with sudo if needed
- Manually check for remaining processes: `pgrep -f k3s`
- Check for remaining mounts: `mount | grep k3s`

## See Also

- [K3s Documentation](https://docs.k3s.io/)
- [Mycelium Documentation](https://github.com/threefoldtech/mycelium)
- [Example Heroscript](templates/examples.heroscript)
