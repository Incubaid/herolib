# Hetzner Module

This module provides a V client for interacting with Hetzner's Robot API, allowing you to manage dedicated servers programmatically. It supports both direct V-lang function calls and execution through HeroScript.

## 1. Configuration

Before using the module, you need to configure at least one client instance with your Hetzner Robot credentials. It's recommended to store your credentials in environment variables for security.

### 1.1 Environment Variables

Create an environment file (e.g., `hetzner_env.sh`) with your credentials:

```bash
export HETZNER_USER="your-robot-username"    # Hetzner Robot API username
export HETZNER_PASSWORD="your-password"      # Hetzner Robot API password
export HETZNER_SSHKEY_NAME="my-key"          # Name of SSH key registered in Hetzner (NOT the key content)
```

Each script defines its own server name and whitelist at the top of the file.

Source the env file before running your scripts:

```bash
source hetzner_env.sh
./your_script.vsh
```

### 1.2 SSH Key Configuration

**Important:** The `sshkey` parameter expects the **name** of an SSH key already registered in your Hetzner Robot account, not the actual key content.

To register a new SSH key with Hetzner, use `key_create`:

```hs
!!hetznermanager.key_create
    key_name: 'my-laptop-key'
    data: 'ssh-ed25519 AAAAC3...'  # The actual public key content
```

Once registered, you can reference the key by name in `configure`:

```hs
!!hetznermanager.configure
    sshkey: 'my-laptop-key'  # Reference the registered key by name
```

### 1.3 HeroScript Configuration

```hs
!!hetznermanager.configure
 name:"main"
 user:"${HETZNER_USER}"
 password:"${HETZNER_PASSWORD}"
 whitelist:"1234567"             // Server ID(s) specific to your script
 sshkey:"${HETZNER_SSHKEY_NAME}"
```

## 2. Usage

You can interact with the Hetzner module in two ways: via HeroScript for automation or directly using V functions for more complex logic.

### 2.1. HeroScript Usage

HeroScript provides a simple, declarative way to execute server operations. You can run a script containing these actions using `playcmds.run()`.

**Example Script:**

```hs

# Place a server into rescue mode
!!hetznermanager.server_rescue
    instance: 'main'               // The configured client instance to use
    server_name: 'your-server-name'  // The name of the server to manage (or use `id`)
    wait: true                     // Wait for the operation to complete
    hero_install: true             // Automatically install Herolib in the rescue system

# Install Ubuntu 24.04 on a server
!!hetznermanager.ubuntu_install
    instance: 'main'
    id: 1234567                   // The ID of the server (or use `server_name`)
    wait: true
    hero_install: true            // Install Herolib on the new OS

# Reset a server
!!hetznermanager.server_reset
    instance: 'main'
    server_name: 'your-server-name'
    wait: true

# Add a new SSH key to your Hetzner account
!!hetznermanager.key_create
    instance: 'main'
    key_name: 'my-laptop-key'
    data: 'ssh-rsa AAAA...'
```

#### Available Heroscript Actions

* `!!hetznermanager.configure`: Configures a new client instance.
  * `name` (string): A unique name for this configuration.
  * `user` (string): Hetzner Robot username.
  * `password` (string): Hetzner Robot password.
  * `whitelist` (string, optional): Comma-separated list of server IDs to restrict operations to.
  * `sshkey` (string, optional): **Name** of an SSH key registered in your Hetzner account (not the key content).
* `!!hetznermanager.server_rescue`: Activates the rescue system.
  * `instance` (string, optional): The client instance to use (defaults to 'default').
  * `server_name` or `id` (string/int): Identifies the target server.
  * `wait` (bool, optional): Wait for the server to reboot into rescue (default: `true`).
  * `hero_install` (bool, optional): Install Herolib in the rescue system (default: `false`).
  * `reset` (bool, optional): Force activation even if already in rescue mode (default: `false`).
* `!!hetznermanager.ubuntu_install`: Performs a fresh installation of Ubuntu 24.04.
  * `instance` (string, optional): The client instance to use (defaults to 'default').
  * `server_name` or `id` (string/int): Identifies the target server.
  * `wait` (bool, optional): Wait for the installation and reboot to complete (default: `true`).
  * `hero_install` (bool, optional): Install Herolib on the newly installed system (default: `false`).
* `!!hetznermanager.server_reset`: Triggers a hardware reset.
  * All parameters are the same as `server_rescue`, except for `hero_install` and `reset`.
* `!!hetznermanager.key_create` / `key_delete`: Manages SSH keys in your account.
  * `instance` (string, optional): The client instance to use.
  * `key_name` (string): The name of the key.
  * `data` (string, for create): The public key data.

### 2.2. V Language Usage

For more granular control, you can call the module functions directly from your V code.

```v
import incubaid.herolib.virt.hetznermanager
import incubaid.herolib.ui.console

// Get a configured client instance by the name you provided during configuration
mut cl := hetznermanager.get(name: 'main')!

// Get list of all servers
servers := cl.servers_list()!
console.print_header('Available Servers')
//팁 In V, you can print structs directly for a quick overview.
println(servers)

// Get detailed info for a specific server by name
server_info := cl.server_info_get(name: 'your-server-name')!
console.print_header('Server details for ${server_info.server_name}')
println(server_info)

// Enable rescue mode and wait for completion
cl.server_rescue(name: 'your-server-name', wait: true, hero_install: true)!
println('Server is now in rescue mode.')

// Reset a server and wait for it to come back online
cl.server_reset(name: 'your-server-name', wait: true)!
println('Server has been reset.')

```

## Features

* Server listing and information retrieval
* Hardware reset functionality
* Rescue mode management with optional Herolib installation
* Automated Ubuntu 24.04 installation
* SSH key management
* Automatic server status monitoring during long operations
* Built-in caching for API responses to reduce rate-limiting
* Integration with Herolib installation tools

## Notes

* The module uses Redis for caching API responses (default 60-second cache duration).
* Server operations that include `wait: true` will monitor the server until the operation completes, providing feedback on the process.
* Reset operations with `wait: true` will timeout after 2 minutes if the server doesn't respond to SSH.
* The module automatically manages `ssh-keygen -R` to remove old host keys during reboots and reinstalls.
* The official API documentation can be found at [https://robot.hetzner.com/doc/webservice/en.html#preface](https://robot.hetzner.com/doc/webservice/en.html#preface).
