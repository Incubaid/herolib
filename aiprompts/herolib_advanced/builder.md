# Builder Module: System Automation and Remote Execution

The `builder` module in Herolib provides a powerful framework for automating system tasks and executing commands on both local and remote machines. It offers a unified interface to manage nodes, execute commands, perform file operations, and maintain persistent state.

## Key Components

- **`BuilderFactory`**: Responsible for creating and managing `Node` instances.
- **`Node`**: Represents a target system (local or remote). It encapsulates system properties (platform, CPU type, environment variables) and provides methods for interaction.
- **`Executor`**: An interface (implemented by `ExecutorLocal` and `ExecutorSSH`) that handles the actual command execution and file operations on the target system.
- **NodeDB (via `Node.done` map)**: A key-value store within each `Node` for persistent state, caching, and tracking execution history.

## Getting Started

### Initializing a Builder and Node

First, import the `builder` module and create a new `BuilderFactory` instance. Then, create a `Node` object, which can represent either the local machine or a remote server.

```v
import incubaid.herolib.builder

// Create a new builder factory
mut b := builder.new()!

// Create a node for the local machine
mut local_node := b.node_local()!

// Create a node for a remote server via SSH
// Format: "user@ip_address:port" or "ip_address:port" or "ip_address"
mut remote_node := b.node_new(ipaddr: "root@195.192.213.2:2222")!

// Node with custom name and debug enabled
mut named_debug_node := b.node_new(
    name: "my_remote_server",
    ipaddr: "user@server.example.com:22",
    debug: true
)!
```

### `Node` Properties

A `Node` object automatically detects and caches system information. You can access these properties:

```v
// Get platform type (e.g., .osx, .ubuntu, .alpine, .arch)
println(node.platform)

// Get CPU architecture (e.g., .intel, .arm)
println(node.cputype)

// Get hostname
println(node.hostname)

// Get environment variables
env_vars := node.environ_get()!
println(env_vars['HOME'])

// Get node information (category, sshkey, user, ipaddress, port)
info := node.info()
println(info['category'])
```

## Command Execution

The `Node` object provides methods to execute commands on the target system.

### `node.exec(args ExecArgs) !string`

Executes a command and returns its standard output.

```v
import incubaid.herolib.builder { ExecArgs }

// Execute a command with stdout
result := node.exec(cmd: "ls -la /tmp", stdout: true)!
println(result)

// Execute silently (no stdout)
node.exec(cmd: "mkdir -p /tmp/my_dir", stdout: false)!
```

### `node.exec_silent(cmd string) !string`

Executes a command silently (no stdout) and returns its output.

```v
output := node.exec_silent("echo 'Hello from remote!'")!
println(output)
```

### `node.exec_interactive(cmd string) !`

Executes a command in an interactive shell.

```v
// This will open an interactive shell session
node.exec_interactive("bash")!
```

### `node.exec_cmd(args NodeExecCmd) !string`

A more advanced command execution method that supports caching, periodic execution, and temporary script handling.

```v
import incubaid.herolib.builder { NodeExecCmd }

// Execute a command, cache its result for 24 hours (48*3600 seconds)
// and provide a description for logging.
result := node.exec_cmd(
    cmd: "apt-get update",
    period: 48 * 3600,
    description: "Update system packages"
)!
println(result)

// Execute a multi-line script
script_output := node.exec_cmd(
    cmd: "
        echo 'Starting script...'
        ls -la /
        echo 'Script finished.'
    ",
    name: "my_custom_script",
    stdout: true
)!
println(script_output)
```

### `node.exec_retry(args ExecRetryArgs) !string`

Executes a command with retries until it succeeds or a timeout is reached.

```v
import incubaid.herolib.builder { ExecRetryArgs }

// Try to connect to a service, retrying every 100ms for up to 10 seconds
result := node.exec_retry(
    cmd: "curl --fail http://localhost:8080/health",
    retrymax: 100, // 100 retries
    period_milli: 100, // 100ms sleep between retries
    timeout: 10 // 10 seconds total timeout
)!
println("Service is up: ${result}")
```

### `node.cmd_exists(cmd string) bool`

Checks if a command exists on the target system.

```v
if node.cmd_exists("docker") {
    println("Docker is installed.")
} else {
    println("Docker is not installed.")
}
```

## File System Operations

The `Node` object provides comprehensive file and directory management capabilities.

### `node.file_write(path string, text string) !`

Writes content to a file on the target system.

```v
node.file_write("/tmp/my_file.txt", "This is some content.")!
```

### `node.file_read(path string) !string`

Reads content from a file on the target system.

```v
content := node.file_read("/tmp/my_file.txt")!
println(content)
```

### `node.file_exists(path string) bool`

Checks if a file or directory exists on the target system.

```v
if node.file_exists("/tmp/my_file.txt") {
    println("File exists.")
}
```

### `node.delete(path string) !`

Deletes a file or directory (recursively for directories) on the target system.

```v
node.delete("/tmp/my_dir")!
```

### `node.list(path string) ![]string`

Lists the contents of a directory on the target system.

```v
files := node.list("/home/user")!
for file in files {
    println(file)
}
```

### `node.dir_exists(path string) bool`

Checks if a directory exists on the target system.

```v
if node.dir_exists("/var/log") {
    println("Log directory exists.")
}
```

### File Transfers (`node.upload` and `node.download`)

Transfer files between the local machine and the target node using `rsync` or `scp`.

```v
import incubaid.herolib.builder { SyncArgs }

// Upload a local file to the remote node
node.upload(
    source: "/local/path/to/my_script.sh",
    dest: "/tmp/remote_script.sh",
    stdout: true // Show rsync/scp output
)!

// Download a file from the remote node to the local machine
node.download(
    source: "/var/log/syslog",
    dest: "/tmp/local_syslog.log",
    stdout: false
)!

// Upload a directory, ignoring .git and examples folders, and deleting extra files on destination
node.upload(
    source: "/local/repo/",
    dest: "~/code/my_project/",
    ignore: [".git/*", "examples/"],
    delete: true,
    fast_rsync: true
)!
```

## Node Database (`node.done`)

The `node.done` map provides a simple key-value store for persistent data on the node. This data is cached in Redis.

```v
// Store a value
node.done_set("setup_complete", "true")!

// Retrieve a value
status := node.done_get("setup_complete") or { "false" }
println("Setup complete: ${status}")

// Check if a key exists
if node.done_exists("initial_config") {
    println("Initial configuration done.")
}

// Print all stored 'done' items
node.done_print()

// Reset all stored 'done' items
node.done_reset()!
```

## Bootstrapping and Updates

The `bootstrapper` module provides functions for installing and updating Herolib components on nodes.

### `node.hero_install() !`

Installs the Herolib environment on the node.

```v
node.hero_install()!
```

### `node.hero_update(args HeroUpdateArgs) !`

Updates the Herolib code on the node, with options for syncing from local, git reset, or git pull.

```v
import incubaid.herolib.builder { HeroUpdateArgs }

// Sync local Herolib code to the remote node (full sync)
node.hero_update(sync_from_local: true, sync_full: true)!

// Reset git repository on the remote node and pull latest from 'dev' branch
node.hero_update(git_reset: true, branch: "dev")!
```

### `node.vscript(args VScriptArgs) !`

Uploads and executes a Vlang script (`.vsh` or `.v`) on the remote node.

```v
import incubaid.herolib.builder { VScriptArgs }

// Upload and execute a local V script on the remote node
node.vscript(path: "/local/path/to/my_script.vsh", sync_from_local: true)!
```

## Port Forwarding

The `portforward_to_local` function allows forwarding a remote port on an SSH host to a local port.

```v
import incubaid.herolib.builder { portforward_to_local, ForwardArgsToLocal }

// Forward remote port 8080 on 192.168.1.100 to local port 9000
portforward_to_local(
    name: "my_app_forward",
    address: "192.168.1.100",
    remote_port: 8080,
    local_port: 9000
)!
```
