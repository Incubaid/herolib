# HeroPrompt Example

Generate structured AI prompts from your codebase with file selection and workspace management.

## Quick Start

Run the example:

```bash
./examples/develop/heroprompt/prompt_example.vsh
```

This example demonstrates the complete workflow from creating a workspace to generating AI prompts.

---

## What is HeroPrompt?

HeroPrompt helps you organize code files and generate structured prompts for AI analysis:

- **Workspace Management**: Organize files into logical workspaces
- **File Selection**: Select specific files or entire directories
- **Prompt Generation**: Generate formatted prompts with file trees and contents
- **Redis Persistence**: All data persists across sessions
- **Active Workspace**: Easily switch between different workspaces

---

## Basic Usage

### 1. Create Instance and Workspace

```v
import freeflowuniverse.herolib.develop.heroprompt

// Create or get instance
mut hp := heroprompt.get(name: 'my_project', create: true)!

// Create workspace (first workspace is automatically active)
mut workspace := hp.new_workspace(
    name: 'my_workspace'
    description: 'My project workspace'
)!
```

### 2. Add Directories

```v
// Add directory and scan all files
mut dir := workspace.add_directory(
    path: '/path/to/your/code'
    name: 'my_code'
    scan: true  // Automatically scans all files and subdirectories
)!
```

### 3. Select Files

```v
// Select specific files
dir.select_file(path: '/path/to/file1.v')!
dir.select_file(path: '/path/to/file2.v')!

// Or select all files in directory
dir.select_all()!
```

### 4. Generate Prompt

```v
// Generate AI prompt with selected files
prompt := workspace.generate_prompt(
    instruction: 'Review these files and suggest improvements'
)!

println(prompt)
```

---

## Generated Prompt Format

The generated prompt includes three sections:

```
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
```v
module main
...
```

</file_contents>

```

---

## API Reference

### Factory Functions

```v
heroprompt.get(name: 'my_project', create: true)!  // Get or create
heroprompt.delete(name: 'my_project')!             // Delete instance
heroprompt.exists(name: 'my_project')!             // Check if exists
heroprompt.list()!                                 // List all instances
```

### HeroPrompt Methods

```v
hp.new_workspace(name: 'ws', description: 'desc')!  // Create workspace
hp.get_workspace('ws')!                             // Get workspace by name
hp.list_workspaces()                                // List all workspaces
hp.delete_workspace('ws')!                          // Delete workspace
hp.get_active_workspace()!                          // Get active workspace
hp.set_active_workspace('ws')!                      // Set active workspace
```

### Workspace Methods

```v
ws.add_directory(path: '/path', name: 'dir', scan: true)!  // Add directory
ws.list_directories()                                       // List directories
ws.remove_directory(id: 'dir_id')!                         // Remove directory
ws.generate_prompt(instruction: 'Review')!                 // Generate prompt
ws.generate_file_map()!                                    // Generate file tree
ws.generate_file_contents()!                               // Generate contents
```

### Directory Methods

```v
dir.select_file(path: '/path/to/file')!   // Select file
dir.select_all()!                          // Select all files
dir.deselect_file(path: '/path/to/file')!  // Deselect file
dir.deselect_all()!                        // Deselect all files
```

---

## Features

### Active Workspace

```v
// Get the currently active workspace
mut active := hp.get_active_workspace()!

// Switch to a different workspace
hp.set_active_workspace('other_workspace')!
```

### Multiple Workspaces

```v
// Create multiple workspaces for different purposes
mut backend := hp.new_workspace(name: 'backend')!
mut frontend := hp.new_workspace(name: 'frontend')!
mut docs := hp.new_workspace(name: 'documentation')!
```

### File Selection

```v
// Select individual files
dir.select_file(path: '/path/to/file.v')!

// Select all files in directory
dir.select_all()!

// Deselect files
dir.deselect_file(path: '/path/to/file.v')!
dir.deselect_all()!
```

---

## Tips

- Always start with cleanup (`heroprompt.delete()`) in examples to ensure a fresh state
- The first workspace created is automatically set as active
- File selection persists to Redis automatically
- Use `scan: true` when adding directories to automatically scan all files
- Selected files are tracked per directory for efficient management
