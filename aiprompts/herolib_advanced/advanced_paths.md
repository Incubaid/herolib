# Pathlib Module: Advanced Listing and Filtering

The `pathlib` module provides powerful capabilities for listing and filtering files and directories, especially through its `list` method. This document explains how to leverage advanced features like regular expressions and various filtering options.

## Advanced File Listing with `path.list()`

The `path.list()` method allows you to retrieve a `PathList` object containing `Path` objects that match specified criteria.

### `ListArgs` Parameters

The `list` method accepts a `ListArgs` struct to control its behavior:

```v
pub struct ListArgs {
pub mut:
	regex         []string // A slice of regular expressions to filter files.
	recursive     bool = true // Whether to list files recursively (default true).
	ignore_default bool = true // Whether to ignore files starting with . and _ (default true).
	include_links bool // Whether to include symbolic links in the list.
	dirs_only     bool // Whether to include only directories in the list.
	files_only    bool // Whether to include only files in the list.
}
```

### Usage Examples

Here are examples demonstrating how to use these advanced filtering options:

#### 1. Listing Files by Regex Pattern

You can use regular expressions to filter files based on their names or extensions. The `regex` parameter accepts a slice of strings, where each string is a regex pattern.

```v
import freeflowuniverse.herolib.core.pathlib

// Get a directory path
mut dir := pathlib.get('/some/directory')!

// List only Vlang files (ending with .v)
mut vlang_files := dir.list(
    regex: [r'.*\.v$']
)!

// List only image files (png, jpg, svg, jpeg)
mut image_files := dir.list(
    regex: [r'.*\.png$', r'.*\.jpg$', r'.*\.svg$', r'.*\.jpeg$']
)!

// List files containing "test" in their name (case-insensitive)
mut test_files := dir.list(
    regex: [r'(?i).*test.*'] // (?i) makes the regex case-insensitive
)!

for path_obj in vlang_files.paths {
    println(path_obj.path)
}
```

#### 2. Controlling Recursion

By default, `list()` is recursive. You can disable recursion to list only items in the current directory.

```v
import freeflowuniverse.herolib.core.pathlib

mut dir := pathlib.get('/some/directory')!

// List only top-level files and directories (non-recursive)
mut top_level_items := dir.list(
    recursive: false
)!

for path_obj in top_level_items.paths {
    println(path_obj.path)
}
```

#### 3. Including or Excluding Hidden Files

The `ignore_default` parameter controls whether files and directories starting with `.` or `_` are ignored.

```v
import freeflowuniverse.herolib.core.pathlib

mut dir := pathlib.get('/some/directory')!

// List all files and directories, including hidden ones
mut all_items := dir.list(
    ignore_default: false
)!

for path_obj in all_items.paths {
    println(path_obj.path)
}
```

#### 4. Including Symbolic Links

By default, symbolic links are ignored when walking the directory structure. Set `include_links` to `true` to include them.

```v
import freeflowuniverse.herolib.core.pathlib

mut dir := pathlib.get('/some/directory')!

// List files and directories, including symbolic links
mut items_with_links := dir.list(
    include_links: true
)!

for path_obj in items_with_links.paths {
    println(path_obj.path)
}
```

#### 5. Listing Only Directories or Only Files

Use `dirs_only` or `files_only` to restrict the results to only directories or only files.

```v
import freeflowuniverse.herolib.core.pathlib

mut dir := pathlib.get('/some/directory')!

// List only directories (recursive)
mut only_dirs := dir.list(
    dirs_only: true
)!

// List only files (non-recursive)
mut only_files := dir.list(
    files_only: true,
    recursive: false
)!

for path_obj in only_dirs.paths {
    println(path_obj.path)
}
```

By combining these parameters, you can create highly specific and powerful file system listing operations tailored to your needs.