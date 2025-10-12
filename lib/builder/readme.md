# Builder Module

The Builder module is a powerful system automation and remote execution framework that provides a unified interface for executing commands and managing files across both local and remote systems.

## Overview

The Builder module consists of several key components:

- **BuilderFactory**: Creates and manages builder instances
- **Node**: Represents a target system (local or remote) with its properties and state
- **Executor**: Interface for command execution and file operations (SSH or Local)
- **NodeDB**: Key-value store at the node level for persistent state

## Getting Started

### Basic Initialization

```v
import incubaid.herolib.builder

// Create a new builder instance
mut b := builder.new()!

// Create a node for remote execution
mut n := b.node_new(ipaddr: "root@195.192.213.2:2222")!

// Or create a local node
mut local_node := builder.node_local()!
```

### Node Configuration

Nodes can be configured with various properties:

```v
// Full node configuration
mut n := b.node_new(
    name: "myserver",      // Optional name for the node
    ipaddr: "root@server.example.com:22",  // SSH connection string
    platform: .ubuntu,     // Target platform type
    debug: true           // Enable debug output
)!
```

## Node Properties

Each node maintains information about:

- Platform type (OSX, Ubuntu, Alpine, Arch)
- CPU architecture (Intel, ARM)
- Environment variables
- System state
- Execution history

The node automatically detects and caches system information for better performance.

## Executor Interface

The executor provides a unified interface for both local and remote operations:

### Command Execution

```v
// Execute command and get output
result := n.exec("ls -la")!

// Execute silently (no output)
n.exec_silent("mkdir -p /tmp/test")!

// Interactive shell
n.shell("bash")!
```

### File Operations

```v
// Write file
n.file_write("/path/to/file", "content")!

// Read file
content := n.file_read("/path/to/file")!

// Check existence
exists := n.file_exists("/path/to/file")

// Delete file/directory
n.delete("/path/to/delete")!

// List directory contents
files := n.list("/path/to/dir")!

// File transfers
n.download("http://example.com/file", "/local/path")!
n.upload("/local/file", "/remote/path")!
```

### Environment Management

```v
// Get all environment variables
env := n.environ_get()!

// Get node information
info := n.info()
```

## Node Database (NodeDB)

The NodeDB provides persistent key-value storage at the node level:

```v
// Store a value
n.done["key"] = "value"
n.save()!

// Load stored values
n.load()!
value := n.done["key"]
```

This is useful for:

- Caching system information
- Storing configuration state
- Tracking execution history
- Maintaining persistent data between sessions

## Best Practices

1. **Error Handling**: Always use the `!` operator for methods that can fail and handle errors appropriately.

2. **Resource Management**: Close connections and clean up resources when done:

```v
defer {
    n.close()
}
```

3. **Debug Mode**: Enable debug mode when troubleshooting:

```v
n.debug_on()  // Enable debug output
n.debug_off() // Disable debug output
```

4. **Platform Awareness**: Check platform compatibility before executing commands:

```v
if n.platform == .ubuntu {
    // Ubuntu-specific commands
} else if n.platform == .osx {
    // macOS-specific commands
}
```

## Examples

See complete examples in:

- Simple usage: `examples/builder/simple.vsh`
- Remote execution: `examples/builder/remote_executor/`
- Platform-specific examples:
  - IPv4: `examples/builder/simple_ip4.vsh`
  - IPv6: `examples/builder/simple_ip6.vsh`

## Implementation Details

The Builder module uses:

- Redis for caching node information
- SSH for secure remote execution
- MD5 hashing for unique node identification
- JSON for data serialization
- Environment detection for platform-specific behavior

For more detailed implementation information, refer to the source code in the `lib/builder/` directory.
