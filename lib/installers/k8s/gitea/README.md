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
installer.db_type = 'sqlite3'       // Default: 'sqlite3' (options: 'sqlite3', 'postgres')
installer.db_path = '/data/gitea/gitea.db'  // Default: '/data/gitea/gitea.db' (for sqlite3)

// PostgreSQL configuration (only used when db_type = 'postgres')
installer.db_host = 'postgres'      // Default: 'postgres' (PostgreSQL service name)
installer.db_name = 'gitea'         // Default: 'gitea' (PostgreSQL database name)
installer.db_user = 'gitea'         // Default: 'gitea' (PostgreSQL user)
installer.db_password = 'gitea'     // Default: 'gitea' (PostgreSQL password)

// Registration
installer.disable_registration = false  // Default: false (allow new user registration)

// Storage
installer.storage_size = '5Gi'      // Default: '5Gi' (PVC storage size)
```

**Note**: When using `db_type = 'postgres'`, a PostgreSQL pod will be automatically deployed in the same namespace. The installer only supports `sqlite3` and `postgres` database types.

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

## PostgreSQL Example

To use PostgreSQL instead of SQLite:

```v
import incubaid.herolib.installers.k8s.gitea

mut installer := gitea.get(
    name:   'mygitea'
    create: true
)!

// Configure to use PostgreSQL
installer.db_type = 'postgres'          // Use PostgreSQL
installer.storage_size = '10Gi'         // Storage for both Gitea and PostgreSQL

// Optional: customize PostgreSQL settings
installer.db_host = 'postgres'          // PostgreSQL service name
installer.db_name = 'gitea'             // Database name
installer.db_user = 'gitea'             // Database user
installer.db_password = 'securepassword' // Database password

// Install (PostgreSQL pod will be deployed automatically)
installer.install()!

println('Gitea with PostgreSQL: https://${installer.hostname}.gent01.grid.tf')
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
