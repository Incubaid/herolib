# Atlas Module

A lightweight document collection manager for V, inspired by doctree but simplified.

## Features

- **Simple Collection Scanning**: Automatically find collections marked with `.collection` files
- **Include Processing**: Process `!!include` actions to embed content from other pages
- **Easy Export**: Copy files to destination with organized structure
- **Optional Redis**: Store metadata in Redis for quick lookups and caching
- **Type-Safe Access**: Get pages, images, and files with error handling
- **Error Tracking**: Built-in error collection and reporting with deduplication

## Quick Start

```v
import incubaid.herolib.data.atlas

// Create a new Atlas
mut a := atlas.new(name: 'my_docs')!

// Scan a directory for collections
a.scan(path: '/path/to/docs')!

// Export to destination
a.export(destination: '/path/to/output')!
```

## Collections

Collections are directories marked with a `.collection` file.

### .collection File Format

```
name:my_collection
```

## Core Concepts

### Collections

A collection is a directory containing:
- A `.collection` file (marks the directory as a collection)
- Markdown pages (`.md` files)
- Images (`.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`)
- Other files

### Page Keys

Pages, images, and files are referenced using the format: `collection:name`

```v
// Get a page
page := a.page_get('guides:introduction')!

// Get an image
img := a.image_get('guides:logo')!

// Get a file
file := a.file_get('guides:diagram')!
```

## Usage Examples

### Scanning for Collections

```v
mut a := atlas.new()!
a.scan(path: './docs')!
```

### Adding a Specific Collection

```v
a.add_collection(name: 'guides', path: './docs/guides')!
```

### Getting Pages

```v
// Get a page
page := a.page_get('guides:introduction')!
content := page.read_content()!

// Check if page exists
if a.page_exists('guides:setup') {
    println('Setup guide found')
}
```

### Getting Images and Files

```v
// Get an image
img := a.image_get('guides:logo')!
println('Image path: ${img.path.path}')
println('Image type: ${img.ftype}')  // .image

// Get a file
file := a.file_get('guides:diagram')!
println('File name: ${file.file_name()}')

// Check existence
if a.image_exists('guides:screenshot') {
    println('Screenshot found')
}
```

### Listing All Pages

```v
pages_map := a.list_pages()
for col_name, page_names in pages_map {
    println('Collection: ${col_name}')
    for page_name in page_names {
        println('  - ${page_name}')
    }
}
```

### Exporting

```v
// Full export with all features
a.export(
    destination: './output'
    reset: true        // Clear destination before export
    include: true      // Process !!include actions
    redis: true        // Store metadata in Redis
)!

// Export without Redis
a.export(
    destination: './output'
    redis: false
)!
```

### Error Handling

```v
// Export and check for errors
a.export(destination: './output')!

// Errors are automatically printed during export
// You can also access them programmatically
for _, col in a.collections {
    if col.has_errors() {
        errors := col.get_errors()
        for err in errors {
            println('Error: ${err.str()}')
        }
        
        // Get error summary by category
        summary := col.error_summary()
        for category, count in summary {
            println('${category}: ${count} errors')
        }
    }
}
```

### Include Processing

Atlas supports simple include processing using `!!include` actions:

```v
// Export with includes processed (default)
a.export(
    destination: './output'
    include: true  // default
)!

// Export without processing includes
a.export(
    destination: './output'
    include: false
)!
```

#### Include Syntax

In your markdown files:

```md
# My Page

!!include collection:page_name

More content here
```

Or within the same collection:

```md
!!include page_name
```

The `!!include` action will be replaced with the content of the referenced page during export.

#### Reading Pages with Includes

```v
// Read with includes processed (default)
mut page := a.page_get('col:mypage')!
content := page.content(include: true)!

// Read raw content without processing includes
content := page.read_content()!
```

#### Circular Include Detection

Atlas automatically detects circular includes and reports them as errors without causing infinite loops.

## Links

Atlas supports standard Markdown links with several formats for referencing pages within collections.

### Link Formats

#### 1. Explicit Collection Reference
Link to a page in a specific collection:
```md
[Click here](guides:introduction)
[Click here](guides:introduction.md)
```

#### 2. Same Collection Reference
Link to a page in the same collection (collection name omitted):
```md
[Click here](introduction)
```

#### 3. Path-Based Reference
Link using a path - **only the filename is used** for matching:
```md
[Click here](some/path/introduction)
[Click here](/absolute/path/introduction)
[Click here](path/to/introduction.md)
```

**Important:** Paths are ignored during link resolution. Only the page name (filename) is used to find the target page within the same collection.

### Link Processing

#### Validation

Check all links in your Atlas:

```v
mut a := atlas.new()!
a.scan(path: './docs')!

// Validate all links
a.validate_links()!

// Check for errors
for _, col in a.collections {
    if col.has_errors() {
        col.print_errors()
    }
}
```

#### Fixing Links

Automatically rewrite links with correct relative paths:

```v
mut a := atlas.new()!
a.scan(path: './docs')!

// Fix all links in place
a.fix_links()!

// Or fix links in a specific collection
mut col := a.get_collection('guides')!
col.fix_links()!
```

**What `fix_links()` does:**
- Finds all local page links
- Calculates correct relative paths
- Rewrites links as `[text](relative/path/pagename.md)`
- Only fixes links within the same collection
- Preserves `!!include` actions unchanged
- Writes changes back to files

#### Example

Before fix:
```md
# My Page

[Introduction](introduction)
[Setup](/some/old/path/setup)
[Guide](guides:advanced)
```

After fix (assuming pages are in subdirectories):
```md
# My Page

[Introduction](../intro/introduction.md)
[Setup](setup.md)
[Guide](guides:advanced)  <!-- Cross-collection link unchanged -->
```

### Link Rules

1. **Name Normalization**: All page names are normalized using `name_fix()` (lowercase, underscores, etc.)
2. **Same Collection Only**: `fix_links()` only rewrites links within the same collection
3. **Cross-Collection Links**: Links with explicit collection references (e.g., `guides:page`) are validated but not rewritten
4. **External Links**: HTTP(S), mailto, and anchor links are ignored
5. **Error Reporting**: Broken links are reported with file, line number, and link details

### Export with Link Validation

Links are automatically validated during export:

```v
a.export(
    destination: './output'
    include: true
)!

// Errors are printed for each collection automatically
```

## Redis Integration

Atlas uses Redis to store metadata about collections, pages, images, and files for fast lookups and caching.

### Redis Data Structure

When `redis: true` is set during export, Atlas stores:

1. **Collection Paths** - Hash: `atlas:path`
   - Key: collection name
   - Value: exported collection directory path

2. **Collection Contents** - Hash: `atlas:<collection_name>`
   - Pages: `page_name` → `page_name.md`
   - Images: `image_name.ext` → `img/image_name.ext`
   - Files: `file_name.ext` → `files/file_name.ext`

### Redis Usage Examples

```v
import incubaid.herolib.data.atlas
import incubaid.herolib.core.base

// Export with Redis metadata (default)
mut a := atlas.new(name: 'docs')!
a.scan(path: './docs')!
a.export(
    destination: './output'
    redis: true  // Store metadata in Redis
)!

// Later, retrieve metadata from Redis
mut context := base.context()!
mut redis := context.redis()!

// Get collection path
col_path := redis.hget('atlas:path', 'guides')!
println('Guides collection exported to: ${col_path}')

// Get page location
page_path := redis.hget('atlas:guides', 'introduction')!
println('Introduction page: ${page_path}')  // Output: introduction.md

// Get image location
img_path := redis.hget('atlas:guides', 'logo.png')!
println('Logo image: ${img_path}')  // Output: img/logo.png
```


## Atlas Save/Load Functionality

This document describes the save/load functionality for Atlas collections, which allows you to persist collection metadata to JSON files and load them in both V and Python.

## Overview

The Atlas module now supports:
- **Saving collections** to `.collection.json` files
- **Loading collections** from `.collection.json` files in V
- **Loading collections** from `.collection.json` files in Python

This enables:
1. Persistence of collection metadata (pages, images, files, errors)
2. Cross-language access to Atlas data
3. Faster loading without re-scanning directories

## V Implementation

### Saving Collections

```v
import incubaid.herolib.data.atlas

// Create and scan atlas
mut a := atlas.new(name: 'my_docs')!
a.scan(path: './docs')!

// Save all collections (creates .collection.json in each collection dir)
a.save_all()!

// Or save a single collection
col := a.get_collection('guides')!
col.save()!
```

### Loading Collections

```v
import incubaid.herolib.data.atlas

// Load single collection
mut a := atlas.new(name: 'loaded')!
mut col := a.load_collection('/path/to/collection')!

println('Pages: ${col.pages.len}')

// Load all collections from directory tree
mut a2 := atlas.new(name: 'all_docs')!
a2.load_from_directory('./docs')!

println('Loaded ${a2.collections.len} collections')
```

### What Gets Saved

The `.collection.json` file contains:
- Collection name and path
- All pages (name, path, collection_name)
- All images (name, ext, path, ftype)
- All files (name, ext, path, ftype)
- All errors (category, page_key, message, file)

**Note:** Circular references (`atlas` and `collection` pointers) are automatically skipped using the `[skip]` attribute and reconstructed during load.

## Python Implementation

### Installation

The Python loader is a standalone script with no external dependencies (uses only Python stdlib):

```bash
# No installation needed - just use the script
python3 lib/data/atlas/atlas_loader.py
```

### Loading Collections

```python
from atlas_loader import Atlas

# Load single collection
atlas = Atlas.load_collection('/path/to/collection')

# Or load all collections from directory tree
atlas = Atlas.load_from_directory('/path/to/docs')

# Access collections
col = atlas.get_collection('guides')
print(f"Pages: {len(col.pages)}")

# Access pages
page = atlas.page_get('guides:intro')
if page:
    content = page.read_content()
    print(content)

# Check for errors
if atlas.has_errors():
    atlas.print_all_errors()
```

### Python API

#### Atlas Class

- `Atlas.load_collection(path, name='default')` - Load single collection
- `Atlas.load_from_directory(path, name='default')` - Load all collections from directory tree
- `atlas.get_collection(name)` - Get collection by name
- `atlas.page_get(key)` - Get page using 'collection:page' format
- `atlas.image_get(key)` - Get image using 'collection:image' format
- `atlas.file_get(key)` - Get file using 'collection:file' format
- `atlas.list_collections()` - List all collection names
- `atlas.list_pages()` - List all pages grouped by collection
- `atlas.has_errors()` - Check if any collection has errors
- `atlas.print_all_errors()` - Print errors from all collections

#### Collection Class

- `collection.page_get(name)` - Get page by name
- `collection.image_get(name)` - Get image by name
- `collection.file_get(name)` - Get file by name
- `collection.has_errors()` - Check if collection has errors
- `collection.error_summary()` - Get error count by category
- `collection.print_errors()` - Print all errors

#### Page Class

- `page.key()` - Get page key in format 'collection:page'
- `page.read_content()` - Read page content from file

#### File Class

- `file.file_name` - Get full filename with extension
- `file.is_image()` - Check if file is an image
- `file.read()` - Read file content as bytes

## Workflow

### 1. V: Create and Save

```v
#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.atlas

// Create atlas and scan
mut a := atlas.new(name: 'my_docs')!
a.scan(path: './docs')!

// Validate
a.validate_links()!

// Save all collections (creates .collection.json in each collection dir)
a.save_all()!

println('Saved ${a.collections.len} collections')
```

### 2. V: Load and Use

```v
#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.atlas

// Load single collection
mut a := atlas.new(name: 'loaded')!
mut col := a.load_collection('/path/to/collection')!

println('Pages: ${col.pages.len}')

// Load all from directory
mut a2 := atlas.new(name: 'all_docs')!
a2.load_from_directory('./docs')!

println('Loaded ${a2.collections.len} collections')
```

### 3. Python: Load and Use

```python
#!/usr/bin/env python3

from atlas_loader import Atlas

# Load single collection
atlas = Atlas.load_collection('/path/to/collection')

# Or load all collections
atlas = Atlas.load_from_directory('/path/to/docs')

# Access pages
page = atlas.page_get('guides:intro')
if page:
    content = page.read_content()
    print(content)

# Check errors
if atlas.has_errors():
    atlas.print_all_errors()
```

## File Structure

After saving, each collection directory will contain:

```
collection_dir/
├── .collection          # Original collection config
├── .collection.json     # Saved collection metadata (NEW)
├── page1.md
├── page2.md
└── img/
    └── image1.png
```

## Error Handling

Errors are preserved during save/load:

```v
// V: Errors are saved
mut a := atlas.new()!
a.scan(path: './docs')!
a.validate_links()!  // May generate errors
a.save_all()!        // Errors are saved to .collection.json

// V: Errors are loaded
mut a2 := atlas.new()!
a2.load_from_directory('./docs')!
col := a2.get_collection('guides')!
if col.has_errors() {
    col.print_errors()
}
```

```python
# Python: Access errors
atlas = Atlas.load_from_directory('./docs')

if atlas.has_errors():
    atlas.print_all_errors()

# Get error summary
col = atlas.get_collection('guides')
if col.has_errors():
    summary = col.error_summary()
    for category, count in summary.items():
        print(f"{category}: {count}")
```


