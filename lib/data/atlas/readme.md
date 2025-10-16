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

### Disabling Redis

If you don't need Redis metadata storage:

```v
a.export(
    destination: './output'
    redis: false  // Skip Redis storage
)!
```

