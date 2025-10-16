# Atlas Module

A lightweight document collection manager for V, inspired by doctree but simplified.

## Features

- **Simple Collection Scanning**: Automatically find collections marked with `.collection` files
- **Minimal Processing**: No markdown parsing, includes, or link resolution
- **Easy Export**: Copy files to destination with simple organization
- **Optional Redis**: Store metadata in Redis for quick lookups
- **Type-Safe Access**: Get pages, images, and files with error handling

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

### Exporting

```v
// Export with Redis metadata
a.export(
    destination: './output'
    reset: true
    redis: true
)!
```

## Redis Structure

When `redis: true` in export:

```
atlas:path  -> hash of collection names to export paths
atlas:my_collection -> hash of file names to relative paths
```

## Key Differences from Doctree

- **No Processing**: Files are copied as-is
- **No Includes**: No `!!wiki.include` processing
- **No Definitions**: No `!!wiki.def` processing  
- **No Link Resolution**: Markdown links are not modified
- **Simpler Structure**: Flat module organization
- **Faster**: No parsing overhead

## When to Use

Use **Atlas** when you need:
- Simple document organization
- Fast file copying without processing
- Basic metadata tracking
- Minimal overhead

Use **Doctree** when you need:
- Markdown processing and transformations
- Include/definition resolution
- Link rewriting
- Complex document workflows