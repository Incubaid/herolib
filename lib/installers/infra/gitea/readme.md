# Installer - Gitea Module

This module provides heroscript actions for installing and managing Gitea.

## Actions

### `gitea.install`

Installs the Gitea Git service.

**Parameters:**

-   `reset` (bool): If true, force a reinstall even if Gitea is already detected. Default: `false`.

**Example:**

```heroscript
!!gitea.install
reset: true