# Pathlib Module

The pathlib module provides a robust way to handle file system operations. Here's a comprehensive overview of how to use it:

## 1. Basic Path Creation

```v
import incubaid.herolib.core.pathlib

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

### 3.1 Regex-Based Filtering

```v
import incubaid.herolib.core.pathlib

mut dir := pathlib.get('/some/code/project')

// Include files matching regex pattern (e.g., all V files)
mut v_files := dir.list(
    regex: [r'.*\.v$']
)!

// Multiple regex patterns (OR logic)
mut source_files := dir.list(
    regex: [r'.*\.v$', r'.*\.ts$', r'.*\.go$']
)!

// Exclude certain patterns
mut no_tests := dir.list(
    regex: [r'.*\.v$'],
    regex_ignore: [r'.*_test\.v$']
)!

// Ignore both default patterns and custom ones
mut important_files := dir.list(
    regex: [r'.*\.v$'],
    regex_ignore: [r'.*_test\.v$', r'.*\.bak$']
)!
```

### 3.2 Simple String-Based Filtering

```v
import incubaid.herolib.core.pathlib

mut dir := pathlib.get('/some/project')

// Include files/dirs containing string in name
mut config_files := dir.list(
    contains: ['config']
)!

// Multiple contains patterns (OR logic)
mut important := dir.list(
    contains: ['main', 'core', 'config'],
    recursive: true
)!

// Exclude files containing certain strings
mut no_backups := dir.list(
    contains_ignore: ['.bak', '.tmp', '.backup']
)!

// Combine contains with exclude
mut python_but_no_cache := dir.list(
    contains: ['.py'],
    contains_ignore: ['__pycache__', '.pyc']
)!
```

### 3.3 Advanced Filtering Options

```v
import incubaid.herolib.core.pathlib

mut dir := pathlib.get('/some/project')

// List only directories
mut dirs := dir.list(
    dirs_only: true,
    recursive: true
)!

// List only files
mut files := dir.list(
    files_only: true,
    recursive: false
)!

// Include symlinks
mut with_links := dir.list(
    regex: [r'.*\.conf$'],
    include_links: true
)!

// Don't ignore hidden files (starting with . or _)
mut all_files := dir.list(
    ignore_default: false,
    recursive: true
)!

// Non-recursive (only in current directory)
mut immediate := dir.list(
    recursive: false
)!

// Access the resulting paths
for path in dirs.paths {
    println('${path.name()}')
}
```

## 4. Path Operations on Lists

```v
mut pathlist := dir.list(regex: [r'.*\.tmp$'])!

// Delete all files matching filter
pathlist.delete()!

// Copy all files to destination
pathlist.copy('/backup/location')!
```

## 5. Common File Operations

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

## 6. Path Scanning with Filters and Executors

Path scanning processes directory trees with custom filter and executor functions.

### 6.1 Basic Scanner Usage

```v
import incubaid.herolib.core.pathlib
import incubaid.herolib.data.paramsparser

// Define a filter function (return true to continue processing)
fn my_filter(mut path pathlib.Path, mut params paramsparser.Params) !bool {
    // Skip files larger than 1MB
    size := path.size()!
    return size < 1_000_000
}

// Define an executor function (process the file)
fn my_executor(mut path pathlib.Path, mut params paramsparser.Params) !paramsparser.Params {
    if path.is_file() {
        content := path.read()!
        println('Processing: ${path.name()} (${content.len} bytes)')
    }
    return params
}

// Run the scan
mut root := pathlib.get_dir(path: '/source/dir')!
mut params := paramsparser.new_params()
root.scan(mut params, [my_filter], [my_executor])!
```

### 6.2 Scanner with Multiple Filters and Executors

```v
import incubaid.herolib.core.pathlib
import incubaid.herolib.data.paramsparser

// Filter 1: Skip hidden files
fn skip_hidden(mut path pathlib.Path, mut params paramsparser.Params) !bool {
    return !path.name().starts_with('.')
}

// Filter 2: Only process V files
fn only_v_files(mut path pathlib.Path, mut params paramsparser.Params) !bool {
    if path.is_file() {
        return path.extension() == 'v'
    }
    return true
}

// Executor 1: Count lines
fn count_lines(mut path pathlib.Path, mut params paramsparser.Params) !paramsparser.Params {
    if path.is_file() {
        content := path.read()!
        lines := content.split_into_lines().len
        params.set('total_lines', (params.get_default('total_lines', '0').int() + lines).str())
    }
    return params
}

// Executor 2: Print file info
fn print_info(mut path pathlib.Path, mut params paramsparser.Params) !paramsparser.Params {
    if path.is_file() {
        size := path.size()!
        println('${path.name()}: ${int(size)} bytes')
    }
    return params
}

// Run scan with all filters and executors
mut root := pathlib.get_dir(path: '/source/code')!
mut params := paramsparser.new_params()
root.scan(mut params, [skip_hidden, only_v_files], [count_lines, print_info])!

total := params.get('total_lines')!
println('Total lines: ${total}')
```

## 7. Sub-path Getters and Checkers

```v
// Get a sub-path with name fixing and case-insensitive matching
path.sub_get(name: 'mysub_file.md', name_fix_find: true, name_fix: true)!

// Check if a sub-path exists
path.sub_exists(name: 'my_sub_dir')!

// File operations
path.file_exists('file.txt')              // bool
path.file_exists_ignorecase('File.Txt')   // bool
path.file_get('file.txt')!                // Path
path.file_get_ignorecase('File.Txt')!     // Path
path.file_get_new('new.txt')!             // Get or create

// Directory operations
path.dir_exists('mydir')                  // bool
path.dir_get('mydir')!                    // Path
path.dir_get_new('newdir')!               // Get or create

// Symlink operations
path.link_exists('mylink')                // bool
path.link_get('mylink')!                  // Path
```

## 8. Path Object Structure

Each Path object contains:

- `path`: The actual path string
- `cat`: Category (file/dir/linkfile/linkdir)
- `exist`: Existence status (yes/no/unknown)

This provides a safe and convenient API for all file system operations in V.