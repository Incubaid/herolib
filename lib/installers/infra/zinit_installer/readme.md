# Installer - Zinit Installer Module

This module provides heroscript actions for installing and managing Zinit.

## Actions

### `zinit_installer.install`

Installs the Zinit process manager.

**Parameters:**

-   `reset` (bool): If true, force a reinstall even if Zinit is already detected. Default: `false`.

**Example:**

```heroscript
!!zinit_installer.install
reset: true