# CryptPad Kubernetes Installer

A Kubernetes installer for CryptPad with TFGrid Gateway integration.

## Quick Start

```v
import incubaid.herolib.installers.k8s.cryptpad

// Create and install CryptPad
mut installer := cryptpad.get(
    name:   'mycryptpad'
    create: true
)!

installer.install()!
```

to change the hostname and the namespace, you can override the default values:

```v
mut installer := cryptpad.get(
    name:   'mycryptpad'
    create: true
)!

installer.hostname = 'customhostname'
installer.namespace = 'customnamespace'
installer.install()!
```

## Usage

### Running the Installer

You can run the installer directly from the command line using the example script:

```bash
./examples/installers/k8s/cryptpad.vsh
```

This will install CryptPad with the default settings. To customize the installation, you can edit the `cryptpad.vsh` file.

### Create an Instance

```v
mut installer := cryptpad.get(
    name:   'mycryptpad'  // Unique name for this instance
    create: true          // Create if doesn't exist
)!
```

The instance name will be used as:

- Kubernetes namespace name
- Hostname prefix (e.g., `mycryptpad.gent01.grid.tf`)

### Install

```v
installer.install()!
```

This will:

1. Generate Kubernetes YAML files for CryptPad and TFGrid Gateway
2. Apply them to your k3s cluster
3. Wait for deployment to be ready

### Destroy

```v
installer.destroy()!
```

Removes all CryptPad resources from the cluster.

## Requirements

- kubectl installed and configured
- k3s cluster running
- Redis server running (for configuration storage)
