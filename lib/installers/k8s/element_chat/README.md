# Element Chat Kubernetes Installer

A Kubernetes installer for Element Chat (Matrix Conduit + Element Web) with TFGrid Gateway integration.

## Overview

This installer deploys a complete Matrix chat solution consisting of:
- **Conduit**: A lightweight Matrix homeserver implementation
- **Element Web**: A modern web client for Matrix
- **TFGW (ThreeFold Gateway)**: Provides public FQDNs with TLS termination

## Quick Start

```v
import incubaid.herolib.installers.k8s.element_chat

// Create and install Element Chat with defaults
mut installer := element_chat.get(
    name:   'myelementchat'
    create: true
)!

installer.install()!
```

## Configuration Options

All configuration options are optional and have sensible defaults:

### Hostnames and Namespace

```v
installer.matrix_hostname = 'matrixchat'    // Default: 'matrixchat'
installer.element_hostname = 'elementchat'  // Default: 'elementchat'
installer.namespace = 'chat'                // Default: 'chat'
```

**Note**: Use only alphanumeric characters in hostnames (no underscores or dashes).

### Conduit (Matrix Homeserver) Configuration

```v
// Server port
installer.conduit_port = 6167               // Default: 6167

// Database configuration
installer.database_backend = 'rocksdb'      // Default: 'rocksdb' (options: 'rocksdb', 'sqlite')
installer.database_path = '/var/lib/matrix-conduit'  // Default: '/var/lib/matrix-conduit'

// Federation and registration
installer.allow_registration = true         // Default: true (allow new user registration)
installer.allow_federation = true           // Default: true (federate with other Matrix servers)

// Logging
installer.log_level = 'info'                // Default: 'info' (options: 'info', 'debug', 'warn', 'error')
```

### Element Web Client Configuration

```v
installer.element_brand = 'Element'         // Default: 'Element' (customize the branding name)
```

## Full Example

```v
import incubaid.herolib.installers.k8s.element_chat

mut installer := element_chat.get(
    name:   'myelementchat'
    create: true
)!

// Configure hostnames
installer.matrix_hostname = 'mymatrix'
installer.element_hostname = 'mychat'
installer.namespace = 'chat'

// Configure Conduit
installer.conduit_port = 6167
installer.database_backend = 'rocksdb'
installer.allow_registration = false        // Disable public registration
installer.allow_federation = true
installer.log_level = 'debug'

// Configure Element
installer.element_brand = 'My Chat'

// Install
installer.install()!

println('Matrix homeserver: https://${installer.matrix_hostname}.gent01.grid.tf')
println('Element web client: https://${installer.element_hostname}.gent01.grid.tf')
```

## Management

### Check Installation Status

```v
if installer.installed()! {
    println('Element Chat is installed')
} else {
    println('Element Chat is not installed')
}
```

### Destroy Deployment

```v
installer.destroy()!
```

This will delete the entire namespace and all resources within it.

## See Also

- [Matrix Conduit Documentation](https://gitlab.com/famedly/conduit)
- [Element Web Documentation](https://github.com/vector-im/element-web)
- [Matrix Protocol](https://matrix.org/)
