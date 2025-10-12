# Heroprompt Module

A hierarchical workspace-based system for organizing code files and directories for AI code analysis. The module follows a clean hierarchical API structure: HeroPrompt → Workspace → Directory.

## Features

- **Hierarchical API**: Clean three-level structure (HeroPrompt → Workspace → Directory)
- **Workspace Management**: Create and manage multiple workspaces within a HeroPrompt instance
- **Directory Support**: Add entire directories with automatic file discovery
- **Flexible Scanning**: Support both automatic scanning (with gitignore) and manual file selection
- **Optional Naming**: Directory names are optional - automatically extracted from directory names
- **GitIgnore Support**: Automatic respect for `.gitignore` and `.heroignore` files during scanning
- **Redis Storage**: Persistent storage using Redis with automatic save on mutations
- **Centralized Logging**: Dual output to console and log file with configurable log levels
- **Concurrency Safe**: Thread-safe global state management with proper locking

## Hierarchical API Structure

```v
import freeflowuniverse.herolib.develop.heroprompt

// 1. Get or create a heroprompt instance
mut hp := heroprompt.get(name: 'my_heroprompt', create: true)!

// 2. Create workspaces from the heroprompt instance
mut workspace1 := hp.new_workspace(name: 'workspace1', description: 'First workspace')!
mut workspace2 := hp.new_workspace(name: 'workspace2', description: 'Second workspace')!

// 3. Add directories to workspaces
// Name parameter is optional - if not provided, extracts from path (last directory name)
dir1 := workspace1.add_directory(
    path: '/path/to/directory'
    name: 'optional_custom_name'  // Optional: defaults to last part of path
)!

// 4. Directory operations - Mode A: Automatic scanning (default)
// add_dir() automatically scans the directory respecting .gitignore
content := dir1.add_dir(path: 'src')!  // Automatically scans by default
println('Scanned ${content.file_count} files, ${content.dir_count} directories')

// 5. Directory operations - Mode B: Manual selective addition
dir2 := workspace1.add_directory(path: '/path/to/dir2')!
file := dir2.add_file(path: 'specific_file.v')!           // Add specific file
dir_content := dir2.add_dir(path: 'src', scan: false)!    // Manual mode (no auto-scan)

// Note: Workspace operations (add_directory, remove_directory, add_file, remove_file)
// automatically save to Redis. No manual hp.save() call needed!
```

## API Overview

### HeroPrompt Factory Functions

- `get(name, fromdb, create, reset)` - Get or create a HeroPrompt instance (main entry point)
  - `name: string` - Instance name (default: 'default')
  - `fromdb: bool` - Force reload from Redis (default: false, uses cache)
  - `create: bool` - Create if doesn't exist (default: false, returns error if not found)
  - `reset: bool` - Delete and recreate if exists (default: false)
- `exists(name)` - Check if HeroPrompt instance exists
- `delete(name)` - Delete a HeroPrompt instance
- `list(fromdb)` - List all HeroPrompt instances

**Usage Examples:**

```v
// Get existing instance (error if not found)
hp := heroprompt.get(name: 'my_heroprompt')!

// Get or create instance
hp := heroprompt.get(name: 'my_heroprompt', create: true)!

// Force reload from Redis (bypass cache)
hp := heroprompt.get(name: 'my_heroprompt', fromdb: true)!

// Reset instance (delete and recreate)
hp := heroprompt.get(name: 'my_heroprompt', reset: true)!
```

### HeroPrompt Methods

- `new_workspace(name, description)` - Create a new workspace
- `get_workspace(name)` - Get an existing workspace
- `list_workspaces()` - List all workspaces
- `delete_workspace(name)` - Delete a workspace
- `save()` - Save HeroPrompt instance to Redis

### Workspace Methods

- `add_directory(path, name, description)` - Add a directory (name is optional)
- `remove_directory(id/path/name)` - Remove a directory
- `get_directory(id)` - Get a directory by ID
- `list_directories()` - List all directories
- `add_file(path)` - Add a standalone file
- `remove_file(id/path/name)` - Remove a file
- `get_file(id)` - Get a file by ID
- `list_files()` - List all standalone files
- `item_count()` - Get total number of items (directories + files)

### Directory Methods

- `add_file(path)` - Add a specific file (relative or absolute path)
- `add_dir(path, scan: bool = true)` - Add all files from a specific directory
  - `scan: true` (default) - Automatically scans the directory respecting .gitignore
  - `scan: false` - Manual mode, returns empty content (for selective file addition)
- `file_count()` - Get number of files in directory
- `display_name()` - Get display name (includes git branch if available)
- `exists()` - Check if directory path still exists
- `refresh_git_info()` - Refresh git metadata

**Note:** The `scan()` method is now private and called automatically by `add_dir()` when `scan=true`.

## Testing

Run all tests:

```bash
v -enable-globals -no-skip-unused -stats test lib/develop/heroprompt
```

Run specific test files:

```bash
v -enable-globals -no-skip-unused test lib/develop/heroprompt/heroprompt_workspace_test.v
v -enable-globals -no-skip-unused test lib/develop/heroprompt/heroprompt_directory_test.v
v -enable-globals -no-skip-unused test lib/develop/heroprompt/heroprompt_file_test.v
```

## Logging Configuration

The module includes centralized logging with dual output (console + file):

```v
mut hp := heroprompt.new(name: 'my_heroprompt', create: true)!

// Configure log path (default: '/tmp/heroprompt_logs')
hp.log_path = '/custom/log/path'

// Suppress logging during tests
hp.run_in_tests = true
```

Log levels: `.error`, `.warning`, `.info`, `.debug`

## Breaking Changes

### v1.0.0

- **Repository → Directory**: The `Repository` struct and all related methods have been renamed to `Directory` to better reflect their purpose
  - `add_repository()` → `add_directory()`
  - `remove_repository()` → `remove_directory()`
  - `get_repository()` → `get_directory()`
  - `list_repositories()` → `list_directories()`
- **Auto-save**: Workspace mutation methods now automatically save to Redis. Manual `hp.save()` calls are no longer required after workspace operations
- **Time Fields**: All time fields now use `ourtime.OurTime` instead of `time.Time`
- **UUID IDs**: All entities now use UUID v4 for unique identifiers instead of custom hash-based IDs

## Examples

See the `examples/develop/heroprompt/` directory for comprehensive examples:

- **01_heroprompt_create_example.vsh** - Creating HeroPrompt instances with workspaces and directories
- **02_heroprompt_get_example.vsh** - Retrieving and working with existing instances
- **README.md** - Detailed guide on running the examples

Run the examples in order (create first, then get) to see the full workflow.
