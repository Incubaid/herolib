# HeroPrompt Module

The `heroprompt` module provides a hierarchical workspace-based system for organizing code files and generating structured AI prompts. It enables developers to select files from multiple directories and generate formatted prompts for AI code analysis.

## Key Features

- **Hierarchical Organization**: HeroPrompt → Workspace → Directory → Files
- **Redis Persistence**: All data persists across sessions using Redis
- **Factory Pattern**: Clean API with `get()`, `delete()`, `exists()`, `list()` functions
- **File Selection**: Select specific files or entire directories for analysis
- **Active Workspace**: Manage multiple workspaces with one active at a time
- **Prompt Generation**: Generate structured prompts with file maps, contents, and instructions
- **Template-Based**: Uses V templates for consistent prompt formatting

## Basic Usage

### 1. Getting Started

```v
import freeflowuniverse.herolib.develop.heroprompt

// Create or get a HeroPrompt instance
mut hp := heroprompt.get(name: 'my_project', create: true)!

// Create a workspace (first workspace is automatically active)
mut workspace := hp.new_workspace(
    name: 'my_workspace'
    description: 'My project workspace'
)!
```

### 2. Adding Directories

```v
// Add directory and automatically scan all files
mut dir := workspace.add_directory(
    path: '/path/to/your/code'
    name: 'backend'
    scan: true  // Scans all files and subdirectories
)!

// Add another directory
mut frontend_dir := workspace.add_directory(
    path: '/path/to/frontend'
    name: 'frontend'
    scan: true
)!
```

### 3. Selecting Files

```v
// Select specific files
dir.select_file(path: '/path/to/your/code/main.v')!
dir.select_file(path: '/path/to/your/code/utils.v')!

// Or select all files in a directory
frontend_dir.select_all()!

// Deselect files
dir.deselect_file(path: '/path/to/your/code/test.v')!

// Deselect all files
dir.deselect_all()!
```

### 4. Generating AI Prompts

```v
// Generate prompt with selected files
prompt := workspace.generate_prompt(
    instruction: 'Review these files and suggest improvements'
)!

println(prompt)

// Or generate with specific files (overrides selection)
prompt2 := workspace.generate_prompt(
    instruction: 'Analyze these specific files'
    selected_files: ['/path/to/file1.v', '/path/to/file2.v']
)!
```

## Factory Functions

### `heroprompt.get(name: string, create: bool) !HeroPrompt`

Gets or creates a HeroPrompt instance.

```v
// Get existing instance or create new one
mut hp := heroprompt.get(name: 'my_project', create: true)!

// Get existing instance only (error if doesn't exist)
mut hp2 := heroprompt.get(name: 'my_project')!
```

### `heroprompt.delete(name: string) !`

Deletes a HeroPrompt instance from Redis.

```v
heroprompt.delete(name: 'my_project')!
```

### `heroprompt.exists(name: string) !bool`

Checks if a HeroPrompt instance exists.

```v
if heroprompt.exists(name: 'my_project')! {
    println('Instance exists')
}
```

### `heroprompt.list() ![]string`

Lists all HeroPrompt instance names.

```v
instances := heroprompt.list()!
for name in instances {
    println('Instance: ${name}')
}
```

## HeroPrompt Methods

### Workspace Management

#### `hp.new_workspace(name: string, description: string, is_active: bool) !&Workspace`

Creates a new workspace. The first workspace is automatically set as active.

```v
mut ws := hp.new_workspace(
    name: 'backend'
    description: 'Backend API workspace'
)!
```

#### `hp.get_workspace(name: string) !&Workspace`

Retrieves an existing workspace by name.

```v
mut ws := hp.get_workspace('backend')!
```

#### `hp.get_active_workspace() !&Workspace`

Returns the currently active workspace.

```v
mut active := hp.get_active_workspace()!
println('Active workspace: ${active.name}')
```

#### `hp.set_active_workspace(name: string) !`

Sets a workspace as active (deactivates all others).

```v
hp.set_active_workspace('frontend')!
```

#### `hp.list_workspaces() []&Workspace`

Lists all workspaces in the instance.

```v
workspaces := hp.list_workspaces()
for ws in workspaces {
    println('Workspace: ${ws.name}')
}
```

#### `hp.delete_workspace(name: string) !`

Deletes a workspace.

```v
hp.delete_workspace('old_workspace')!
```

## Workspace Methods

### Directory Management

#### `ws.add_directory(path: string, name: string, scan: bool) !&Directory`

Adds a directory to the workspace.

```v
mut dir := ws.add_directory(
    path: '/path/to/code'
    name: 'my_code'
    scan: true  // Automatically scans all files
)!
```

#### `ws.list_directories() []&Directory`

Lists all directories in the workspace.

```v
dirs := ws.list_directories()
for dir in dirs {
    println('Directory: ${dir.name}')
}
```

#### `ws.remove_directory(id: string) !`

Removes a directory from the workspace.

```v
ws.remove_directory(id: dir.id)!
```

### Prompt Generation

#### `ws.generate_prompt(instruction: string, selected_files: []string, show_all_files: bool) !string`

Generates a complete AI prompt with file map, contents, and instructions.

```v
// Use selected files (from select_file() calls)
prompt := ws.generate_prompt(
    instruction: 'Review the code'
)!

// Or specify files explicitly
prompt2 := ws.generate_prompt(
    instruction: 'Analyze these files'
    selected_files: ['/path/to/file1.v', '/path/to/file2.v']
    show_all_files: false
)!
```

#### `ws.generate_file_map(selected_files: []string, show_all: bool) !string`

Generates a hierarchical tree structure of files.

```v
file_map := ws.generate_file_map(
    selected_files: ['/path/to/file1.v']
    show_all: false
)!
println(file_map)
```

#### `ws.generate_file_contents(selected_files: []string, include_path: bool) !string`

Generates formatted file contents.

```v
contents := ws.generate_file_contents(
    selected_files: ['/path/to/file1.v']
    include_path: true
)!
println(contents)
```

## Directory Methods

### File Selection

#### `dir.select_file(path: string) !`

Marks a file as selected.

```v
dir.select_file(path: '/path/to/file.v')!
```

#### `dir.select_all() !`

Selects all files in the directory and subdirectories.

```v
dir.select_all()!
```

#### `dir.deselect_file(path: string) !`

Deselects a file.

```v
dir.deselect_file(path: '/path/to/file.v')!
```

#### `dir.deselect_all() !`

Deselects all files in the directory.

```v
dir.deselect_all()!
```

### Directory Information

#### `dir.exists() bool`

Checks if the directory exists on the filesystem.

```v
if dir.exists() {
    println('Directory exists')
}
```

#### `dir.get_contents() !DirectoryContent`

Gets all files in the directory (scans if needed).

```v
content := dir.get_contents()!
println('Files: ${content.files.len}')
```

## Generated Prompt Format

The generated prompt uses a template with three sections:

```prompt
<user_instructions>
Review these files and suggest improvements
</user_instructions>

<file_map>
my_project/
├── src/
│   ├── main.v *
│   └── utils.v *
└── README.md *
</file_map>

<file_contents>
File: /path/to/src/main.v
\```v
module main

fn main() {
    println('Hello')
}
\```

</file_contents>

```

Files marked with `*` in the file_map are the selected files included in the prompt.

## Complete Example

```v
import freeflowuniverse.herolib.develop.heroprompt

mut hp := heroprompt.get(name: 'my_app', create: true)!
mut ws := hp.new_workspace(name: 'backend')!

mut src_dir := ws.add_directory(path: '/path/to/src', name: 'source', scan: true)!
src_dir.select_file(path: '/path/to/src/main.v')!

prompt := ws.generate_prompt(instruction: 'Review the code')!
println(prompt)

heroprompt.delete(name: 'my_app')!
```

## Tips

- Use `heroprompt.delete()` at start for fresh state
- First workspace is automatically active
- Changes auto-save to Redis
- Use `scan: true` to discover all files
- Create separate workspaces for different contexts
