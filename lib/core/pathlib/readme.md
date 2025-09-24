# Pathlib Module

The pathlib module provides a robust way to handle file system operations. Here's a comprehensive overview of how to use it:

## 1. Basic Path Creation

```v
import freeflowuniverse.herolib.core.pathlib

// Get a basic path object
mut path := pathlib.get('/some/path')

// Create a directory (with parent dirs)
mut dir := pathlib.get_dir(
    path: '/some/dir'
    create: true
)!

// Create/get a file
mut file := pathlib.get_file(
    path: '/some/file.txt'
    create: true
)!
```

## 2. Path Properties and Operations

```v
// Get various path forms
abs_path := path.absolute()      // Full absolute path
real_path := path.realpath()     // Resolves symlinks
short_path := path.shortpath()   // Uses ~ for home dir

// Get path components
name := path.name()              // Filename with extension
name_no_ext := path.name_no_ext() // Filename without extension
dir_path := path.path_dir()      // Directory containing the path

// Check path properties
if path.exists() { /* exists */ }
if path.is_file() { /* is file */ }
if path.is_dir() { /* is directory */ }
if path.is_link() { /* is symlink */ }
```

## 3. File Listing and Filtering

```v
// List all files in a directory (recursive by default)
mut dir := pathlib.get('/some/dir')
mut pathlist := dir.list()!

// List only files matching specific extensions using regex
mut pathlist_images := dir.list(
    regex: [r'.*\.png$', r'.*\.jpg$', r'.*\.svg$', r'.*\.jpeg$'],
    recursive: true
)!

// List only directories
mut pathlist_dirs := dir.list(
    dirs_only: true,
    recursive: true
)!

// List only files
mut pathlist_files := dir.list(
    files_only: true,
    recursive: false  // only in current directory
)!

// Include symlinks in the results
mut pathlist_with_links := dir.list(
    include_links: true
)!

// Don't ignore hidden files (those starting with . or _)
mut pathlist_all := dir.list(
    ignore_default: false
)!

// Access the resulting paths
for path in pathlist.paths {
    println(path.path)
}

// Perform operations on all paths in the list
pathlist.copy('/destination/dir')!
pathlist.delete()!
```

## 4. Common File Operations

```v
// Empty a directory
mut dir := pathlib.get_dir(
    path: '/some/dir'
    empty: true
)!

// Delete a path
mut path := pathlib.get_dir(
    path: '/path/to/delete'
    delete: true
)!

// Get working directory
mut wd := pathlib.get_wd()
```

## Features

The module handles common edge cases:
- Automatically expands ~ to home directory
- Creates parent directories as needed
- Provides proper error handling with V's result type
- Checks path existence and type
- Handles both absolute and relative paths

## Path Object Structure

Each Path object contains:
- `path`: The actual path string
- `cat`: Category (file/dir/link)
- `exist`: Existence status

This provides a safe and convenient API for all file system operations in V.

## 5. Sub-path Getters and Checkers

The `pathlib` module provides methods to get and check for the existence of sub-paths (files, directories, and links) within a given path.

```v
// Get a sub-path (file or directory) with various options
path.sub_get(name:"mysub_file.md", name_fix_find:true, name_fix:true)!

// Check if a sub-path exists
path.sub_exists(name:"my_sub_dir")!

// Check if a file exists
path.file_exists("my_file.txt")

// Check if a file exists (case-insensitive)
path.file_exists_ignorecase("My_File.txt")

// Get a file as a Path object
path.file_get("another_file.txt")!

// Get a file as a Path object (case-insensitive)
path.file_get_ignorecase("Another_File.txt")!

// Get a file, create if it doesn't exist
path.file_get_new("new_file.txt")!

// Check if a link exists
path.link_exists("my_link")

// Check if a link exists (case-insensitive)
path.link_exists_ignorecase("My_Link")

// Get a link as a Path object
path.link_get("some_link")!

// Check if a directory exists
path.dir_exists("my_directory")

// Get a directory as a Path object
path.dir_get("another_directory")!

// Get a directory, create if it doesn't exist
path.dir_get_new("new_directory")!
```
