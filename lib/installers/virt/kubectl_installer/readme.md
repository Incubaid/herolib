# kubectl_installer

Installs the kubectl CLI tool for interacting with Kubernetes clusters.

## Usage

```v
import incubaid.herolib.installers.virt.kubectl_installer

// Get the installer
mut installer := kubectl_installer.get()!

// Install kubectl
installer.install()!
```

## Example heroscript

```hero
!!kubectl_installer.configure
    kubectl_version: 'v1.33.1'

!!kubectl_installer.install
```
