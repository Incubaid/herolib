# Pathlib Usage Guide

## Overview

The pathlib module provides a comprehensive interface for handling file system operations. Key features include:

- Robust path handling for files, directories, and symlinks
- Support for both absolute and relative paths
- Automatic home directory expansion (~)
- Recursive directory operations
- Path filtering and listing
- File and directory metadata access

## Basic Usage

### Importing pathlib
```v
import freeflowuniverse.herolib.core.pathlib
```

### Creating Path Objects

This will figure out if the path is a dir, file and if it exists.

```v
// Create a Path object for a file
mut file_path := pathlib.get("path/to/file.txt")

// Create a Path object for a directory
mut dir_path := pathlib.get("path/to/directory")
```

if you know in advance if you expect a dir or file its better to use `pathlib.get_dir(path:...,create:true)` or `pathlib.get_file(path:...,create:true)`.

### Basic Path Operations
```v
// Get absolute path
abs_path := file_path.absolute()

// Get real path (resolves symlinks)
real_path := file_path.realpath()

// Check if path exists
if file_path.exists() {
    // Path exists
}
```

## Path Properties and Methods

### Path Types
```v
// Check if path is a file
if file_path.is_file() {
    // Handle as file
}

// Check if path is a directory
if dir_path.is_dir() {
    // Handle as directory
}

// Check if path is a symlink
if file_path.is_link() {
    // Handle as symlink
}
```

### Path Normalization
```v
// Normalize path (remove extra slashes, resolve . and ..)
normalized_path := file_path.path_normalize()

// Get path directory
dir_path := file_path.path_dir()

// Get path name without extension
name_no_ext := file_path.name_no_ext()
```

## File and Directory Operations

### File Operations
```v
// Write to file
file_path.write("Content to write")!

// Read from file
content := file_path.read()!

// Delete file
file_path.delete()!
```

### Directory Operations
```v
// Create directory
mut dir := pathlib.get_dir(
    path: "path/to/new/dir"
    create: true
)!

// List directory contents
mut dir_list := dir.list()!

// Delete directory
dir.delete()!
```

### Symlink Operations
```v
// Create symlink
file_path.link("path/to/symlink", delete_exists: true)!

// Resolve symlink
real_path := file_path.realpath()
```

## Advanced Operations

### Path Copying
```v
// Copy file to destination
file_path.copy(dest: "path/to/destination")!
```

### Recursive Operations
```v
// List directory recursively
mut recursive_list := dir.list(recursive: true)!

// Delete directory recursively
dir.delete()!
```

### Path Filtering
```v
// List files matching pattern
mut filtered_list := dir.list(
    regex: [r".*\.txt$"],
    recursive: true
)!
```

## Best Practices

### Error Handling
```v
if file_path.exists() {
    // Safe to operate
} else {
    // Handle missing file
}
```

