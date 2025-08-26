
# Podman Module

Tools to work with containers using Podman and Buildah.

## Platform Support

- **Linux**: Full support
- **macOS**: Full support (requires podman installation)
- **Windows**: Not supported

## Basic Usage

```v
#!/usr/bin/env -S v -n -w -enable-globals run

import freeflowuniverse.herolib.virt.podman
import freeflowuniverse.herolib.ui.console

console.print_header("PODMAN Demo")

// Create a new podman factory
// install: true will install podman if not present
// herocompile: true will compile hero for use in containers
mut factory := podman.new(install: false, herocompile: false)!

// Create a new builder
mut builder := factory.builder_new(name: 'test', from: 'docker.io/ubuntu:latest')!

// Run commands in the builder
builder.run('apt-get update && apt-get install -y curl')!

// Open interactive shell
builder.shell()!
```

## buildah tricks

```bash
#find the containers as have been build, these are the active ones you can work with
buildah ls
#see the images
buildah images
```

result is something like

```bash
CONTAINER ID  BUILDER  IMAGE ID     IMAGE NAME                       CONTAINER NAME
a9946633d4e7     *                  scratch                          base
86ff0deb00bf     *     4feda76296d6 localhost/builder:latest         base_go_rust
```

some tricks

```bash
#run interactive in one (here we chose the builderv one)
buildah run --terminal --env TERM=xterm base /bin/bash
#or
buildah run --terminal --env TERM=xterm default /bin/bash
#or
buildah run --terminal --env TERM=xterm base_go_rust /bin/bash

```

to check inside the container about diskusage

```bash
apt install ncdu
ncdu
```

## Create Container

```v
import freeflowuniverse.herolib.virt.podman
import freeflowuniverse.herolib.ui.console

console.print_header("Create a container")

mut factory := podman.new()!

// Create a container with advanced options
// See https://docs.podman.io/en/latest/markdown/podman-run.1.html
mut container := factory.container_create(
    name: 'mycontainer'
    image_repo: 'ubuntu'
    image_tag: 'latest'
    // Resource limits
    memory: '1g'
    cpus: 0.5
    // Network config
    network: 'bridge'
    network_aliases: ['myapp', 'api']
    // DNS config
    dns_servers: ['8.8.8.8', '8.8.4.4']
    dns_search: ['example.com']
    interactive: true  // Keep STDIN open
    mounts: [
        'type=bind,src=/data,dst=/container/data,ro=true'
    ]
    volumes: [
        '/config:/etc/myapp:ro'
    ]
    published_ports: [
        '127.0.0.1:8080:80'
    ]
)!

// Start the container
container.start()!

// Execute commands in the container
container.execute('apt-get update', false)!

// Open interactive shell
container.shell()!
```

## future

should make this module compatible with <https://github.com/containerd/nerdctl>
