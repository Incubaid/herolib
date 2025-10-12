
# Podman Module

A clean, consolidated module for working with Podman containers and Buildah builders.

## Overview

This module provides **two complementary APIs** for Podman functionality:

1. **Simple API**: Direct functions for quick operations (`podman.run_container()`, `podman.list_containers()`)
2. **Factory API**: Advanced factory pattern for complex workflows and state management

### Key Features

- **Container Management**: Create, run, stop, and manage containers
- **Image Management**: List, inspect, and manage container images
- **Builder Integration**: Seamless Buildah integration for image building
- **Unified Error Handling**: Consistent error types across all operations
- **Cross-Platform**: Works on Linux and macOS

## Platform Support

- **Linux**: Full support
- **macOS**: Full support (requires podman installation)
- **Windows**: Not supported

## Module Structure

- **`factory.v`** - Main entry point with both simple API and factory pattern
- **`container.v`** - All container types and management functions
- **`image.v`** - All image types and management functions
- **`builder.v`** - Buildah integration for image building
- **`errors.v`** - Unified error handling system

## API Approaches

### 1. Simple API (Quick Operations)

For simple container operations, use the direct functions:

```v
import incubaid.herolib.virt.podman

// List containers and images
containers := podman.list_containers(true)!  // true = include stopped
images := podman.list_images()!

// Run a container
options := podman.RunOptions{
    name: 'my-app'
    detach: true
    ports: ['8080:80']
    volumes: ['/data:/app/data']
    env: {'ENV': 'production'}
}
container_id := podman.run_container('nginx:latest', options)!

// Manage containers
podman.stop_container(container_id)!
podman.remove_container(container_id, force: true)!
podman.remove_image('nginx:latest', force: false)!
```

### 2. Factory API (Advanced Workflows)

For complex operations and state management, use the factory pattern:

```v
import incubaid.herolib.virt.podman

// Create factory (with auto-install)
mut factory := podman.new(install: true, herocompile: false)!

// Create containers with advanced options
container := factory.container_create(
    name: 'web-server'
    image_repo: 'nginx'
    image_tag: 'alpine'
    forwarded_ports: ['80:8080']
    memory: '512m'
    cpus: 1.0
)!

// Build images with Buildah
mut builder := factory.builder_new(
    name: 'my-app'
    from: 'ubuntu:latest'
)!
builder.run('apt-get update && apt-get install -y nodejs')!
builder.copy('./app', '/usr/src/app')!
builder.set_entrypoint('node /usr/src/app/server.js')!
builder.commit('my-app:latest')!

// Seamless integration: build with buildah, run with podman
app_container_id := factory.create_from_buildah_image('my-app:latest', config)!
```

## Container Operations

### Simple Container Management

```v
// List containers
all_containers := podman.list_containers(true)!  // Include stopped
running_containers := podman.list_containers(false)!  // Only running

// Inspect container details
container_info := podman.inspect_container('container_id')!
println('Container status: ${container_info.status}')

// Container lifecycle
podman.stop_container('container_id')!
podman.remove_container('container_id', force: true)!
```

### Advanced Container Creation

```v
// Factory approach with full configuration
mut factory := podman.new()!

container := factory.container_create(
    name: 'web-app'
    image_repo: 'nginx'
    image_tag: 'alpine'

    // Resource limits
    memory: '1g'
    cpus: 2.0

    // Networking
    forwarded_ports: ['80:8080', '443:8443']
    network: 'bridge'

    // Storage
    mounted_volumes: ['/data:/app/data:ro', '/logs:/var/log']

    // Environment
    env: {'NODE_ENV': 'production', 'PORT': '8080'}

    // Runtime options
    detach: true
    remove_when_done: false
)!
```

## Image Operations

### Simple Image Management

```v
// List all images
images := podman.list_images()!
for image in images {
    println('${image.repository}:${image.tag} - ${image.size}')
}

// Remove images
podman.remove_image('nginx:latest', force: false)!
podman.remove_image('old-image:v1.0', force: true)!  // Force removal
```

### Factory Image Management

```v
mut factory := podman.new()!

// Load and inspect images
factory.images_load()!  // Refresh image cache
images := factory.images_get()!

// Find specific images
image := factory.image_get(repo: 'nginx', tag: 'latest')!
println('Image ID: ${image.id}')

// Check if image exists
if factory.image_exists(repo: 'my-app', tag: 'v1.0')! {
    println('Image exists')
}
```

## Builder Integration (Buildah)

### Creating and Using Builders

```v
mut factory := podman.new()!

// Create a builder
mut builder := factory.builder_new(
    name: 'my-app-builder'
    from: 'ubuntu:22.04'
    delete: true  // Remove existing builder with same name
)!

// Build operations
builder.run('apt-get update && apt-get install -y nodejs npm')!
builder.copy('./package.json', '/app/')!
builder.run('cd /app && npm install')!
builder.copy('./src', '/app/src')!

// Configure the image
builder.set_workingdir('/app')!
builder.set_entrypoint('node src/server.js')!

// Commit to image (automatically available in podman)
builder.commit('my-app:latest')!

// Use the built image immediately with podman
container_id := factory.create_from_buildah_image('my-app:latest', config)!
```

### Build-to-Run Workflow

```v
// Complete workflow: build with buildah, run with podman
container_id := factory.build_and_run_workflow(
    build_config: build_config,
    run_config: run_config,
    image_name: 'my-app'
)!
```

## Error Handling

The module provides comprehensive error handling with specific error types:

```v
// Simple API error handling
containers := podman.list_containers(true) or {
    match err {
        podman.ContainerError {
            println('Container operation failed: ${err.msg()}')
        }
        podman.ImageError {
            println('Image operation failed: ${err.msg()}')
        }
        else {
            println('Unexpected error: ${err.msg()}')
        }
    }
    []podman.PodmanContainer{}
}

// Factory API error handling
mut factory := podman.new() or {
    println('Failed to create factory: ${err}')
    exit(1)
}

container := factory.container_create(args) or {
    if err is podman.ContainerError {
        println('Container creation failed: ${err.msg()}')
    } else if err is podman.ImageError {
        println('Image error: ${err.msg()}')
    } else {
        println('Creation failed: ${err.msg()}')
    }
    return
}

// Builder error handling
mut builder := factory.builder_new(name: 'test', from: 'nonexistent:latest') or {
    println('Builder creation failed: ${err.msg()}')
    return
}

builder.run('invalid_command') or {
    println('Command execution failed: ${err.msg()}')
    // Continue with fallback or cleanup
}
```

## Installation and Setup

```v
import incubaid.herolib.virt.podman

// Automatic installation
mut factory := podman.new(install: true)!  // Will install podman if needed

// Manual installation check
mut factory := podman.new(install: false) or {
    println('Podman not found. Please install podman first.')
    exit(1)
}
```

## Complete Example

See `examples/virt/podman/podman.vsh` for a comprehensive example that demonstrates:

- Automatic podman installation
- Simple API usage (run_container, list_containers, etc.)
- Factory API usage (advanced container creation, builder workflows)
- Error handling patterns
- Integration between buildah and podman
- Cleanup and uninstallation

## API Reference

### Simple API Functions

- `run_container(image, options)` - Run a container with simple options
- `list_containers(all)` - List containers (all=true includes stopped)
- `list_images()` - List all available images
- `inspect_container(id)` - Get detailed container information
- `stop_container(id)` - Stop a running container
- `remove_container(id, force)` - Remove a container
- `remove_image(id, force)` - Remove an image

### Factory API Methods

- `new(install, herocompile)` - Create a new PodmanFactory
- `container_create(args)` - Create container with advanced options
- `create_from_buildah_image(image, config)` - Run container from buildah image
- `build_and_run_workflow(build_config, run_config, image_name)` - Complete workflow
- `builder_new(name, from)` - Create a new buildah builder
- `load()` - Refresh factory state (containers, images, builders)
- `reset_all()` - Remove all containers, images, and builders (CAREFUL!)

## Future Enhancements

- **nerdctl compatibility**: Make module compatible with [nerdctl](https://github.com/containerd/nerdctl)
- **Docker compatibility**: Add Docker runtime support
- **Kubernetes integration**: Support for pod and deployment management
- **Registry operations**: Enhanced image push/pull capabilities
