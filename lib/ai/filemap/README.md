# filemap Module

Parse directories or formatted strings into file maps with automatic ignore pattern support.

## Features

- 📂 Walk directories recursively and build file maps
- 🚫 Respect `.gitignore` and `.heroignore` ignore patterns with directory scoping
- 📝 Parse custom `===FILE:name===` format into file maps
- 📦 Export/write file maps to disk
- 🛡️ Robust, defensive parsing (handles spaces, variable `=` length, case-insensitive)

## Quick Start

### From Directory Path

```v
import incubaid.herolib.lib.ai.filemap

mut cw := filemap.new()
mut fm := cw.filemap_get(path: '/path/to/project')!

// Iterate files
for path, content in fm.content {
    println('${path}: ${content.len} bytes')
}
```

### From Formatted String

```v
content_str := '
===FILE:main.v===
fn main() {
    println("Hello!")
}
===FILE:utils/helper.v===
pub fn help() {}
===END===
'

mut cw := filemap.new()
mut fm := cw.parse(content_str)!

println(fm.get('main.v')!)
```

## FileMap Operations

```v
// Get file content
content := fm.get('path/to/file.txt')!

// Set/modify file
fm.set('new/file.txt', 'content here')

// Find files by prefix
files := fm.find('src/')

// Export to directory
fm.export('/output/dir')!

// Write updates to directory
fm.write('/project/dir')!

// Convert back to formatted string
text := fm.content()
```

## File Format

### Full Files

```
===FILE:path/to/file.txt===
File content here
Can span multiple lines
===END===
```

### Partial Content (for future morphing)

```
===FILECHANGE:src/models.v===
struct User {
    id int
}
===END===
```

### Both Together

```
===FILE:main.v===
fn main() {}
===FILECHANGE:utils.v===
fn helper() {}
===END===
```

## Parsing Robustness

Parser handles variations:

```
===FILE:name.txt===     // Standard
= = FILE : name.txt = = // Extra spaces
===file:name.txt===     // Lowercase
==FILE:name.txt==       // Different = count
```

## Error Handling

Errors are collected in `FileMap.errors`:

```v
mut fm := cw.filemap_get(content: str)!

if fm.errors.len > 0 {
    for err in fm.errors {
        println('Line ${err.linenr}: ${err.message}')
    }
}
```

## Ignore Patterns

- Respects `.gitignore` and `.heroignore` in any directory
- Patterns are scoped to the directory that contains them
- Default patterns include `.git/`, `node_modules/`, `*.pyc`, etc.
- Use `/` suffix for directory patterns: `dist/`
- Use `*` for wildcards: `*.log`
- Lines starting with `#` are comments

Example `.heroignore`:

```
build/
*.tmp
.env
__pycache__/
```
