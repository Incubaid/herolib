# HeropromptBackend

Backend module for HeroPrompt - a code context generator for LLM prompts.

Provides workspace and directory management with file listing, content reading, and search functionality. Uses the filemap module for automatic ignore pattern support (.gitignore, .heroignore).

## Quick Start

```v
import incubaid.herolib.ai.heroprompt_backend

fn main() {
    // Create or get a backend instance
    mut backend := heroprompt_backend.new(name: 'default')!

    // Create a workspace
    mut ws := backend.create_workspace(name: 'My Project')!
    println('Created workspace: ${ws.name} (${ws.id})')

    // Add directories to the workspace
    backend.add_dir(
        workspace_id: ws.id
        path: '/path/to/my/project'
    )!

    // List files (respects .gitignore patterns)
    files := backend.list_files(workspace_id: ws.id)!
    for dir_id, file_map in files {
        println('Directory ${dir_id}:')
        for path, _ in file_map.content {
            println('  - ${path}')
        }
    }

    // Search within workspace
    results := backend.search(
        workspace_id: ws.id
        query: 'fn main'
        max_results: 10
    )!
    for result in results {
        println('${result.path}:${result.line_number}: ${result.line}')
    }

    // Generate context for selected files
    context := backend.generate_context(
        workspace_id: ws.id
        file_paths: ['/path/to/my/project/main.v', '/path/to/my/project/lib.v']
    )!
    println(context)
}
```

## API Reference

### Workspace Operations

| Function | Description |
|----------|-------------|
| `create_workspace(name)` | Create a new workspace (name defaults to "Untitled Workspace") |
| `list_workspaces()` | List all workspaces |
| `get_workspace(id)` | Get a workspace by ID |
| `update_workspace(id, name)` | Update workspace name |
| `delete_workspace(id)` | Delete a workspace |

### Directory Operations

| Function | Description |
|----------|-------------|
| `add_dir(workspace_id, path, name)` | Add a directory to a workspace |
| `list_dirs(workspace_id)` | List directories in a workspace |
| `delete_dir(workspace_id, dir_id)` | Remove a directory from a workspace |

### File Operations

| Function | Description |
|----------|-------------|
| `list_files(workspace_id, dir_id)` | List files with ignore pattern support |
| `get_file_tree(dir_path)` | Get hierarchical file tree structure |
| `get_file_content(path)` | Read file content |
| `get_files_content(paths)` | Read multiple files |

### Search & Context

| Function | Description |
|----------|-------------|
| `search(workspace_id, query, ...)` | Search for text in workspace files |
| `generate_context(workspace_id, file_paths)` | Generate formatted context string |

## Data Structures

### Workspace

```v
pub struct Workspace {
pub mut:
    id         string      // Unique identifier
    name       string      // Display name
    dirs       []Directory // Directories in this workspace
    created_at i64         // Unix timestamp
    updated_at i64         // Unix timestamp
}
```

### Directory

```v
pub struct Directory {
pub mut:
    id         string // Unique identifier
    path       string // Absolute path
    name       string // Display name
    created_at i64    // Unix timestamp
}
```

### SearchResult

```v
pub struct SearchResult {
pub mut:
    path        string // File path
    line_number int    // Line number (1-based)
    line        string // Matching line
    context     string // Context around match
}
```

## Ignore Patterns

The module automatically respects:
- `.gitignore` files (up to repository root)
- `.heroignore` files
- Default patterns: `node_modules/`, `__pycache__/`, `.git/`, `*.pyc`, etc.

