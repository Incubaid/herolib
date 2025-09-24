# Installer - CoreDNS Module

This module provides heroscript actions for installing and managing CoreDNS.

## Actions

### `coredns.install`

Installs the CoreDNS server.

**Parameters:**

-   `reset` (bool): If true, force a reinstall even if CoreDNS is already detected. Default: `false`.

**Example:**

```heroscript
!!coredns.install
reset: true