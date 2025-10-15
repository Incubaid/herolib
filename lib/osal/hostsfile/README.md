# Hosts File Manager

This module provides functionality to manage the system's hosts file (`/etc/hosts`) in a safe and structured way. It supports both Linux and macOS systems, automatically handling sudo permissions when required.

## Features

- Read and parse the system's hosts file
- Add new host entries with IP and domain
- Remove host entries by domain
- Manage sections with comments
- Remove or clear entire sections
- Check for existing domains
- Automatic sudo handling for macOS and Linux when needed

## Usage

Create a file `example.vsh`:

```v
#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.osal.core.hostsfile
import os

// Create a new instance by reading the hosts file
mut hosts := hostsfile.new() or {
    eprintln('Failed to read hosts file: ${err}')
    exit(1)
}

// Add a new host entry to a section
hosts.add_host('127.0.0.1', 'mysite.local', 'Development') or {
    eprintln('Failed to add host: ${err}')
    exit(1)
}

// Remove a host entry
hosts.remove_host('mysite.local') or {
    eprintln('Failed to remove host: ${err}')
    exit(1)
}

// Check if a domain exists
if hosts.exists('example.com') {
    println('Domain exists')
}

// Clear all entries in a section
hosts.clear_section('Development') or {
    eprintln('Failed to clear section: ${err}')
    exit(1)
}

// Remove an entire section
hosts.remove_section('Development') or {
    eprintln('Failed to remove section: ${err}')
    exit(1)
}

// Save changes back to the hosts file
// This will automatically use sudo when needed
hosts.save() or {
    eprintln('Failed to save hosts file: ${err}')
    exit(1)
}
```

## File Structure

The hosts file is organized into sections marked by comments. For example:

```
# Development
127.0.0.1    localhost
127.0.0.1    mysite.local

# Production
192.168.1.100    prod.example.com
```

## Error Handling

All functions that can fail return a Result type and should be handled appropriately:

```v
hosts.add_host('127.0.0.1', 'mysite.local', 'Development') or {
    eprintln('Failed to add host: ${err}')
    exit(1)
}
```

## Platform Support

- Linux: Direct write with fallback to sudo if needed
- macOS: Always uses sudo due to system restrictions
