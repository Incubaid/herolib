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

!!include page:'collection:page_name'

More content here
```

The `!!include` action will be replaced with the content of the referenced page during export.

#### Reading Pages with Includes

```v
// Read with includes processed (requires atlas reference)
mut page := a.page_get('col:mypage')!
mut col := a.get_collection('col')!
content := page.read_content_with_includes(a)!

// Read raw content without processing includes  
content := page.read_content()!
```

#### Circular Include Detection

Atlas automatically detects circular includes and will return an error if detected.