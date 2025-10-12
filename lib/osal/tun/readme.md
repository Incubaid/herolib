# TUN Interface Management

This module provides functionality to manage TUN (network tunnel) interfaces on Linux and macOS systems.

## Functions

### available() !bool

Checks if TUN/TAP functionality is available on the system:

- Linux: Verifies `/dev/net/tun` exists and is a character device
- macOS: Checks for `utun` interfaces using `ifconfig` and `sysctl`

### free() !string

Returns the name of an available TUN interface:

- Linux: Returns first available interface from tun0-tun10
- macOS: Returns next available utun interface number

## Example Usage

```v

#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.osal.core.tun


// Check if TUN is available
if available := tun.available() {
    if available {
        println('TUN is available on this system')
        
        // Get a free TUN interface name
        if interface_name := tun.free() {
            println('Found free TUN interface: ${interface_name}')
            
            // Example: Now you could use this interface name
            // to set up your tunnel
        } else {
            println('Error finding free interface: ${err}')
        }
    } else {
        println('TUN is not available on this system')
    }
} else {
    println('Error checking TUN availability: ${err}')
}


```

## Platform Support

The module automatically detects the platform (Linux/macOS) and uses the appropriate methods:

- On Linux: Uses `/dev/net/tun` and `ip link` commands
- On macOS: Uses `utun` interfaces via `ifconfig`

## Error Handling

Both functions return a Result type, so errors should be handled appropriately:

- Unsupported platform errors
- Interface availability errors
- System command execution errors
