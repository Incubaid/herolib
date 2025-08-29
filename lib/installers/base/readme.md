# Installer - Base Module

This module provides heroscript actions to install and configure base system dependencies.

## Actions

### `base.install`

Installs base packages for the detected operating system (OSX, Ubuntu, Alpine, Arch).

**Parameters:**

-   `reset` (bool): If true, reinstalls packages even if they are already present. Default: `false`.
-   `develop` (bool): If true, installs development packages. Default: `false`.

**Example:**

```heroscript
!!base.install
develop: true
```

### `base.develop`

Installs development packages for the detected operating system.

**Parameters:**

-   `reset` (bool): If true, reinstalls packages. Default: `false`.

**Example:**

```heroscript
!!base.develop
reset: true
```

### `base.redis_install`

Installs and configures Redis server.

**Parameters:**

-   `port` (int): Port for Redis to listen on. Default: `6379`.
-   `ipaddr` (string): IP address to bind to. Default: `localhost`.
-   `reset` (bool): If true, reinstalls and reconfigures Redis. Default: `false`.
-   `start` (bool): If true, starts the Redis server after installation. Default: `true`.

**Example:**

```heroscript
!!base.redis_install
port: 6380
```
