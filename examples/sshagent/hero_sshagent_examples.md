# Hero SSH Agent Management Tool

The Hero SSH Agent Management Tool provides comprehensive SSH agent lifecycle management with cross-platform compatibility for macOS and Linux. It integrates seamlessly with shell profiles and implements intelligent SSH agent lifecycle management, automatic key discovery and loading, and remote key deployment capabilities.

## Features

- 🔐 **Single SSH Agent Instance Enforcement**: Ensures exactly one SSH agent is running with persistent socket management
- 🚀 **Smart Key Loading**: Auto-loads single keys from ~/.ssh/ directory with passphrase prompting
- 🌐 **Remote Key Deployment**: Interactive SSH key deployment to remote machines
- 🔄 **Agent Health Verification**: Comprehensive health checks through ssh-agent -l functionality
- 📝 **Shell Profile Integration**: Automatic initialization in shell profiles
- 🎯 **Cross-Platform**: Works on macOS and Linux

## Installation

The SSH agent functionality is built into the hero binary. After compiling hero:

```bash
./cli/compile.vsh
```

The hero binary will be available at `/Users/mahmoud/hero/bin/hero`

## Commands

### `hero sshagent profile`

Primary initialization command that ensures exactly one SSH agent is running on a consistent socket, performs health checks, manages agent lifecycle without losing existing keys, and automatically loads SSH keys when only one is present in ~/.ssh/ directory.

```bash
# Initialize SSH agent with smart key loading
hero sshagent profile
```

**Features:**

- Ensures single SSH agent instance
- Verifies agent health and responsiveness
- Auto-loads single SSH keys
- Updates shell profile for automatic initialization
- Preserves existing loaded keys

### `hero sshagent list`

Lists all available SSH keys and their current status.

```bash
# List all SSH keys
hero sshagent list
```

### `hero sshagent status`

Shows comprehensive SSH agent status and diagnostics.

```bash
# Show agent status
hero sshagent status
```

### `hero sshagent generate`

Generates a new SSH key pair.

```bash
# Generate new SSH key
hero sshagent generate -n my_new_key

# Generate and immediately load
hero sshagent generate -n my_new_key -l
```

### `hero sshagent load`

Loads a specific SSH key into the agent.

```bash
# Load specific key
hero sshagent load -n my_key
```

### `hero sshagent forget`

Removes a specific SSH key from the agent.

```bash
# Remove key from agent
hero sshagent forget -n my_key
```

### `hero sshagent reset`

Removes all loaded SSH keys from the agent.

```bash
# Reset agent (remove all keys)
hero sshagent reset
```

### `hero sshagent push`

Interactive SSH key deployment to remote machines with automatic key selection when multiple keys exist, target specification via user@hostname format, and streamlined single-key auto-selection.

```bash
# Deploy SSH key to remote machine
hero sshagent push -t user@hostname

# Deploy specific key to remote machine
hero sshagent push -t user@hostname -k my_key

# Deploy to custom port
hero sshagent push -t user@hostname:2222
```

**Features:**

- Automatic key selection when only one key exists
- Interactive key selection for multiple keys
- Support for custom SSH ports
- Uses ssh-copy-id when available, falls back to manual deployment

### `hero sshagent auth`

Remote SSH key authorization ensuring proper key installation on target machines, support for explicit key specification via -key parameter, and verification of successful key addition.

```bash
# Verify SSH key authorization
hero sshagent auth -t user@hostname

# Verify specific key authorization
hero sshagent auth -t user@hostname -k my_key
```

## Examples

### Basic Workflow

```bash
# 1. Initialize SSH agent
hero sshagent profile

# 2. Check status
hero sshagent status

# 3. Generate a new key if needed
hero sshagent generate -n production_key

# 4. Load the key
hero sshagent load -n production_key

# 5. Deploy to remote server
hero sshagent push -t user@production-server.com

# 6. Verify authorization
hero sshagent auth -t user@production-server.com
```

### Advanced Usage

```bash
# Deploy specific key to multiple servers
hero sshagent push -t user@server1.com -k production_key
hero sshagent push -t user@server2.com:2222 -k production_key

# Verify access to all servers
hero sshagent auth -t user@server1.com -k production_key
hero sshagent auth -t user@server2.com:2222 -k production_key

# List all keys and their status
hero sshagent list

# Reset agent if needed
hero sshagent reset
```

## Technical Specifications

### Cross-Platform Compatibility

- **Socket Management**: Uses ~/.ssh/hero-agent.sock for consistent socket location
- **Shell Integration**: Supports ~/.profile, ~/.bash_profile, ~/.bashrc, and ~/.zshrc
- **Process Management**: Robust SSH agent lifecycle management
- **Platform Support**: macOS and Linux (Windows not supported)

### Security Features

- **Single Agent Enforcement**: Prevents multiple conflicting agents
- **Secure Socket Paths**: Uses user home directory for socket files
- **Proper Permissions**: Ensures correct file permissions (0700 for .ssh, 0600 for keys)
- **Input Validation**: Validates all user inputs and target specifications
- **Connection Testing**: Verifies SSH connections before reporting success

### Error Handling

- **Network Connectivity**: Handles network failures gracefully
- **Authentication Failures**: Provides clear error messages for auth issues
- **Key Management**: Validates key existence and format
- **Target Validation**: Ensures proper target format (user@hostname[:port])

## Environment Variables

- `HERO_DEBUG=1`: Enable debug output for troubleshooting

## Integration with Development Environments

The tool is designed to work seamlessly with development environments:

- **Preserves existing SSH agent state** during initialization
- **Non-destructive operations** that don't interfere with existing workflows
- **Shell profile integration** for automatic initialization
- **Compatible with existing SSH configurations**

## Troubleshooting

### Common Issues

1. **Multiple SSH agents running**

   ```bash
   hero sshagent profile  # Will cleanup and ensure single agent
   ```

2. **Keys not loading**

   ```bash
   hero sshagent status   # Check agent status
   hero sshagent reset    # Reset if needed
   ```

3. **Remote deployment failures**

   ```bash
   hero sshagent auth -t user@hostname  # Verify connectivity
   ```

### Debug Mode

Enable debug output for detailed troubleshooting:

```bash
HERO_DEBUG=1 hero sshagent profile
```

## Shell Profile Integration

The `hero sshagent profile` command automatically adds initialization code to your shell profile:

```bash
# Hero SSH Agent initialization
if [ -f "/Users/username/.ssh/hero-agent.sock" ]; then
    export SSH_AUTH_SOCK="/Users/username/.ssh/hero-agent.sock"
fi
```

This ensures the SSH agent is available in new shell sessions.
