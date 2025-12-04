# K3s Installer

Installs and manages K3s (lightweight Kubernetes) clusters with Mycelium IPv6 networking support.

## Features

- First master node initialization with `--cluster-init`
- Additional master nodes for HA clusters
- Worker node joining
- Mycelium IPv6 auto-detection
- Automatic token generation
- Join script generation for other nodes

## Usage

```v
import incubaid.herolib.installers.virt.k3s_installer

// Get the installer
mut installer := k3s_installer.get()!

// Install as first master
installer.install_master()!

// Start K3s
installer.start()!
```

## Example heroscript

### First Master Node

```hero
!!k3s_installer.configure
    name: 'k3s_master'
    k3s_version: 'v1.33.1'
    data_dir: '~/hero/var/k3s'
    node_name: 'master-1'

!!k3s_installer.install_master name:'k3s_master'
!!k3s_installer.start name:'k3s_master'
```

### Join as Worker Node

```hero
!!k3s_installer.configure
    name: 'k3s_worker'
    k3s_version: 'v1.33.1'
    node_name: 'worker-1'
    token: '<token-from-master>'
    master_url: 'https://[<master-ipv6>]:6443'

!!k3s_installer.install_worker name:'k3s_worker'
!!k3s_installer.start name:'k3s_worker'
```

### Destroy Installation

```hero
!!k3s_installer.destroy
```
