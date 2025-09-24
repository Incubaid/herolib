# Installer - Vlang Module

This module provides heroscript actions for installing and managing the V programming language and its tools.

## Actions

### `vlang.install`

Installs the V language compiler.

**Parameters:**

-   `reset` (bool): If true, force a reinstall even if V is already detected. Default: `false`.

**Example:**

```heroscript
!!vlang.install
reset: true
```

### `vlang.v_analyzer_install`

Installs the `v-analyzer` language server for V.

**Parameters:**

-   `reset` (bool): If true, force a reinstall. Default: `false`.

**Example:**

```heroscript
!!vlang.v_analyzer_install