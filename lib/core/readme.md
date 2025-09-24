# Core Module

The Core module provides fundamental system-level functionality for the Hero framework. It handles platform detection, system operations, and provides essential utilities used throughout the framework.

## Main Features

### Platform Management
- Platform detection (OSX, Ubuntu, Alpine, Arch)
- CPU architecture detection (Intel, ARM)
- System information retrieval (hostname, init system)
- Cross-platform compatibility utilities

### Memory Database
- Thread-safe in-memory key-value store
- Global state management
- Caching for system information

### Sudo Operations
- Permission management and verification
- Sudo requirement detection
- Path access rights checking
- Command elevation handling

### Submodules

- **base**: Context and session management
- **httpconnection**: HTTP client functionality
- **logger**: Logging infrastructure
- **pathlib**: Path manipulation and handling
- **playbook**: Execution plbooks
- **redisclient**: Redis database client
- **rootpath**: Root path management
- **smartid**: Identifier management
- **texttools**: Text manipulation utilities
- **vexecutor**: Command execution

## Platform Support

The module supports multiple platforms:
- macOS (Intel and ARM)
- Ubuntu
- Alpine Linux
- Arch Linux

And CPU architectures:
- x86_64 (Intel)
- ARM64/AArch64

## Usage

The core module provides essential functionality used by other Hero framework components. Key features include:

### Interactivity Check & Influence on delete

```
import freeflowuniverse.herolib.installers.lang.golang
import freeflowuniverse.herolib.core

core.interactive_set()! //make sure the sudo works so we can do things even if it requires those rights

//this will allow files which are in sudo area to still get them removed but its important interactive is set on the context.
golang.install(reset:false)!
```


### Platform Detection
```v
// Check platform type
if core.is_linux()! {
    // Linux-specific code
}

// Check CPU architecture
if core.is_linux_arm()! {
    // ARM-specific code
}
```

### Memory Database
```v
// Store values
core.memdb_set('key', 'value')

// Retrieve values
value := core.memdb_get('key')
```

### Sudo Operations

The sudo operations module provides comprehensive permission management and command elevation handling:

```v
// Check if sudo is required for the current user
if core.sudo_required()! {
    // Handle sudo requirements
    // Returns false if user is root or on macOS
    // Returns true if user has sudo privileges
}

// Verify path permissions and accessibility
path := core.sudo_path_check('/path/to/check')! {
    // Returns the path if accessible
    // Errors if path requires sudo rights
}

// Check if a path is accessible without sudo
if core.sudo_path_ok('/usr/local/bin')! {
    // Returns false for protected directories like:
    // /usr/, /boot, /etc, /root/
    // Returns true if path is accessible
}

// Check and modify commands that require sudo
cmd := core.sudo_cmd_check('ufw enable')! {
    // Automatically adds 'sudo' prefix if:
    // 1. Command requires elevated privileges
    // 2. User doesn't have sudo rights
    // 3. Running in interactive mode
}

// Check if current process has sudo rights
if core.sudo_rights_check()! {
    // Returns true if:
    // - Running as root user
    // - Has necessary sudo privileges
}
```
