# Rootpath Module

The rootpath module provides functionality for managing the Hero environment directory structure and path handling. It ensures consistent access to Hero-specific directories and provides utilities for path manipulation.

## Core Functions

### Directory Management

- `herodir()` - Returns the root directory for the Hero environment (`~/hero`)
- `bindir()` - Returns the binary directory (`~/hero/bin`)
- `vardir()` - Returns the variable directory (`~/hero/var`)
- `cfgdir()` - Returns the configuration directory (`~/hero/cfg`)
- `ensure_hero_dirs()` - Creates all necessary Hero directories if they don't exist

### Path Utilities

- `shell_expansion(s string)` - Expands shell-like path expressions (e.g., `~` or `{HOME}`) to full paths
- `path_ensure(s string)` - Ensures a given path exists by creating it if necessary
- `hero_path(s string)` - Constructs a path underneath the Hero root directory
- `hero_path_ensure(s string)` - Ensures a Hero-specific path exists and returns it

## Usage Example

```vsh
import incubaid.herolib.core.rootpath

// Get and ensure Hero directories exist
hero_root := rootpath.ensure_hero_dirs()

// Work with Hero-specific paths
ensured_path := rootpath.hero_path_ensure('data/myapp')

// Expand shell paths
full_path := rootpath.shell_expansion('~/hero/custom/path')

```

## Directory Structure

The module manages the following directory structure:

```
~/hero/
  ├── bin/     # Binary files
  ├── var/     # Variable data
  └── cfg/     # Configuration files
```
