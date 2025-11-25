# crun_installer

Installer for the crun container runtime - a fast and lightweight OCI runtime written in C.

## Features

- **Simple Package Installation**: Installs crun via system package manager
- **Cross-Platform Support**: Works on Ubuntu, Arch Linux, and macOS
- **Clean Uninstall**: Removes crun cleanly from the system

## Quick Start

### Using V Code

```v
import incubaid.herolib.installers.virt.crun_installer

mut crun := crun_installer.get()!

// Install crun
crun.install()!

// Check if installed
if crun.installed()! {
    println('crun is installed')
}

// Uninstall crun
crun.destroy()!
```

### Using Heroscript

```hero
!!crun_installer.install

!!crun_installer.destroy
```

## Platform Support

- **Ubuntu/Debian**: Installs via `apt`
- **Arch Linux**: Installs via `pacman`
- **macOS**: ⚠️ Not supported - crun is Linux-only. Use Docker Desktop or Podman Desktop on macOS instead.

## What is crun?

crun is a fast and low-memory footprint OCI Container Runtime fully written in C. It is designed to be a drop-in replacement for runc and is used by container engines like Podman.

## See Also

- **crun client**: `lib/virt/crun` - V client for interacting with crun
- **podman installer**: `lib/installers/virt/podman` - Podman installer (includes crun)
