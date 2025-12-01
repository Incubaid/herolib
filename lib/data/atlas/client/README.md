# AtlasClient

A simple API for accessing document collections exported by the `atlas` module.

## What It Does

AtlasClient provides methods to:

- List collections, pages, files, and images
- Check if resources exist
- Get file paths and content
- Access metadata (links, errors)
- Copy images from pages

## Quick Start

```v
import incubaid.herolib.web.atlas_client

// Create client
mut client := atlas_client.new(export_dir: '/tmp/atlas_export')!

// List collections
collections := client.list_collections()!

// Get page content
content := client.get_page_content('my_collection', 'page_name')!

// Check for errors
if client.has_errors('my_collection')! {
    errors := client.get_collection_errors('my_collection')!
}
```

## Export Structure

Atlas exports to this structure:

```txt
export_dir/
├── content/
│   └── collection_name/
│       ├── page.md
│       ├── image.png
│       └── file.pdf
└── meta/
    └── collection_name.json
```

## Key Methods

**Collections:**

- `list_collections()` - List all collections

**Pages:**

- `list_pages(collection)` - List pages in collection
- `page_exists(collection, page)` - Check if page exists
- `get_page_content(collection, page)` - Get page markdown content
- `get_page_path(collection, page)` - Get page file path

**Files & Images:**

- `list_files(collection)` - List non-page, non-image files
- `list_images(collection)` - List image files
- `get_file_path(collection, file)` - Get file path
- `get_image_path(collection, image)` - Get image path
- `copy_images(collection, page, dest)` - Copy page images to dest/img/
- `copy_files(collection, page, dest)` - Copy page files to dest/files/

**Metadata:**

- `get_collection_metadata(collection)` - Get full metadata
- `get_page_links(collection, page)` - Get links from page
- `get_collection_errors(collection)` - Get collection errors
- `has_errors(collection)` - Check if collection has errors

## Naming Convention

Names are normalized using `name_fix()`:

- `My_Page-Name.md` → `my_page_name`
- Removes: dashes, special chars
- Converts to lowercase
- Preserves underscores

## Example

See `examples/data/atlas_client/basic_usage.vsh` for a complete working example.

## See Also

- `lib/data/atlas/` - Atlas module for exporting collections
- `lib/web/doctreeclient/` - Alternative client for doctree collections
