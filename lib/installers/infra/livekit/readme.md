# Installer - Livekit Module

This module provides heroscript actions for installing and managing Livekit.

## Actions

### `livekit.install`

Installs the Livekit server.

**Parameters:**

-   `reset` (bool): If true, force a reinstall even if Livekit is already detected. Default: `false`.

**Example:**

```heroscript
!!livekit.install
reset: true