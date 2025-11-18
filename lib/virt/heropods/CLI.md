# HeroPods CLI

The `hero pods` command provides a Docker/Podman-like CLI interface for managing HeroPods containers.

## Installation

Build the hero CLI:

```bash
v -o ~/hero cli/hero.v
```

## Commands

### List Containers

```bash
hero pods ps
```

Lists all containers (running and stopped) with their status and PID.

### List Images

```bash
hero pods images ls
```

Lists all available container images with size and creation time.

### Create Container

```bash
hero pods create --name mycontainer alpine_3_20
# or with Docker URL
hero pods create --name mycontainer --docker-url docker.io/library/alpine:3.20
```

Creates a new container from an image.

### Start Container

```bash
hero pods start mycontainer
```

Starts a stopped container.

### Stop Container

```bash
hero pods stop mycontainer
```

Stops a running container.

### Remove Container

```bash
hero pods rm mycontainer
# Force remove running container
hero pods rm --force mycontainer
```

Removes/deletes a container.

### Execute Command

```bash
hero pods exec mycontainer ls -la
hero pods exec mycontainer /bin/sh
```

Executes a command inside a running container.

### Inspect Container

```bash
hero pods inspect mycontainer
```

Shows detailed information about a container including:

- Status (running/stopped)
- PID (if running)
- Network namespace access commands
- Crun management commands

## Example Workflow

```bash
# List available images
hero pods images ls

# Create a container
hero pods create --name test1 alpine_3_20

# Start the container
hero pods start test1

# Execute commands in the container
hero pods exec test1 ip addr show
hero pods exec test1 ping -c 2 8.8.8.8

# Inspect the container
hero pods inspect test1

# Stop the container
hero pods stop test1

# Remove the container
hero pods rm test1
```

## Manual Container Access

For manual testing and debugging, you can access containers directly using the information from `hero pods inspect`:

```bash
# Get container PID
hero pods inspect mycontainer

# Access container network namespace
nsenter -t <PID> -n ip addr show

# Get shell in container
nsenter -t <PID> -n -m -p /bin/sh

# Use crun directly
crun --root /Users/user/.heropods/default/runtime exec mycontainer /bin/sh
```

## Notes

- All containers are managed by the default HeroPods instance
- Container networking uses bridge mode with automatic IP allocation
- Images are pulled and extracted using Podman
- The OCI runtime used is crun
