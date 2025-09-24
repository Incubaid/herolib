# Podman

Podman is a lightweight container manager that allows users to manage and run containers without requiring a daemon, providing flexibility and security for containerized applications.

## Using Podman in VLang

The following example demonstrates how to use the Podman installer in a VLang script. It checks if Podman is installed, removes it if found, or installs it if not.

### Example Code (VLang)
```v
import freeflowuniverse.herolib.installers.virt.podman as podman_installer

mut podman := podman_installer.get()!

// To install
podman.install()!

// To remove
podman.destroy()!
```
