# Gitea Kubernetes Installer

A Kubernetes installer for Gitea with TFGrid Gateway integration.

## Overview

This installer deploys a complete Git hosting solution:

- **Gitea**: A lightweight self-hosted Git service
- **TFGW (ThreeFold Gateway)**: Provides public FQDNs with TLS termination

## Quick Start

```v
import incubaid.herolib.installers.k8s.gitea

// Create and install Gitea with defaults
mut installer := gitea.get(
    name:   'mygitea'
    create: true
)!

installer.install()!
```

## Configuration Options

All configuration options are optional and have sensible defaults:

### Hostname and Namespace

```v
installer.hostname = 'giteaapp'     // Default: 'giteaapp'
installer.namespace = 'forge'       // Default: '${installer.name}-gitea-namespace'
```

**Note**: Use only alphanumeric characters in hostnames (no underscores or dashes).

### Gitea Server Configuration

```v
// Server port
installer.http_port = 3000          // Default: 3000

// Database configuration
installer.db_type = 'sqlite3'       // Default: 'sqlite3' (options: 'sqlite3', 'postgres', 'mysql')
installer.db_path = '/data/gitea/gitea.db'  // Default: '/data/gitea/gitea.db'

// Registration
installer.disable_registration = false  // Default: false (allow new user registration)

// Storage
installer.storage_size = '5Gi'      // Default: '5Gi' (PVC storage size)
```

## Full Example

```v
import incubaid.herolib.installers.k8s.gitea

mut installer := gitea.get(
    name:   'mygitea'
    create: true
)!

// Configure hostname and namespace
installer.hostname = 'mygit'
installer.namespace = 'forge'

// Configure Gitea
installer.http_port = 3000
installer.db_type = 'sqlite3'
installer.disable_registration = true   // Disable public registration
installer.storage_size = '10Gi'         // Increase storage

// Install
installer.install()!

println('Gitea: https://${installer.hostname}.gent01.grid.tf')
```

## Management

### Check Installation Status

```v
if gitea.installed()! {
    println('Gitea is installed')
} else {
    println('Gitea is not installed')
}
```

### Destroy Deployment

```v
installer.destroy()!
```

This will delete the entire namespace and all resources within it.

## See Also

- [Gitea Documentation](https://docs.gitea.io/)
- [Gitea GitHub Repository](https://github.com/go-gitea/gitea)
