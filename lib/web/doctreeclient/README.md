# DocTreeClient

DocTreeClient provides a simple API for accessing document collections that have been processed and stored by the `doctree` module. It allows you to:

- List available collections
- List pages, files, and images within collections
- Check if specific pages, files, or images exist
- Get file paths for pages, files, and images
- Retrieve content of pages

The client works with Redis as a backend storage system, where document collections are indexed and their metadata is stored.

## Usage

### Creating a Client

```v
import incubaid.herolib.web.doctreeclient

// Create a new DocTreeClient instance
mut client := doctreeclient.new()!
```

### Working with Collections

```v
// List all available collections
collections := client.list_collections()!
println('Available collections: ${collections}')

// Check if a collection exists by trying to list its pages
if client.page_exists('my_collection', 'some_page') {
    println('Collection and page exist')
}
```

### Working with Pages

```v
// List all pages in a collection
pages := client.list_pages('my_collection')!
println('Pages in collection: ${pages}')

// Check if a specific page exists
if client.page_exists('my_collection', 'introduction') {
    println('Page exists')
}

// Get the file path for a page
page_path := client.get_page_path('my_collection', 'introduction')!
println('Page path: ${page_path}')

// Get the content of a page
content := client.get_page_content('my_collection', 'introduction')!
println('Page content: ${content}')
```

### Working with Files

```v
// List all files in a collection
files := client.list_files('my_collection')!
println('Files in collection: ${files}')

// Check if a specific file exists
if client.file_exists('my_collection', 'document.pdf') {
    println('File exists')
}

// Get the file path
file_path := client.get_file_path('my_collection', 'document.pdf')!
println('File path: ${file_path}')
```

### Working with Images

```v
// List all images in a collection
images := client.list_images('my_collection')!
println('Images in collection: ${images}')

// Check if a specific image exists
if client.image_exists('my_collection', 'diagram.png') {
    println('Image exists')
}

// Get the image path
image_path := client.get_image_path('my_collection', 'diagram.png')!
println('Image path: ${image_path}')
```

## Complete Example

Here's a complete example that demonstrates how to use DocTreeClient with a document collection:

```v
module main

import incubaid.herolib.web.doctreeclient
import incubaid.herolib.data.doctree

fn main() {
    // First, populate Redis with doctree data
    mut tree := doctree.new(name: 'example_docs')!

    // Scan a git repository containing documentation
    tree.scan(
        git_url: 'https://github.com/example/docs'
        git_pull: true
    )!

    // Export the doctree to Redis and local filesystem
    tree.export(
        destination: '/tmp/docs_export'
        reset: true
    )!
    
    // Create a DocTreeClient instance
    mut client := doctreeclient.new()!
    
    // List all collections
    collections := client.list_collections()!
    println('Available collections: ${collections}')
    
    // Use the first collection
    if collections.len > 0 {
        collection_name := collections[0]
        
        // List pages in the collection
        pages := client.list_pages(collection_name)!
        println('Pages in collection: ${pages}')
        
        // Get content of the first page
        if pages.len > 0 {
            page_name := pages[0]
            content := client.get_page_content(collection_name, page_name)!
            println('Content of ${page_name}:')
            println(content)
        }
        
        // List and display images
        images := client.list_images(collection_name)!
        println('Images in collection: ${images}')
        
        // List and display other files
        files := client.list_files(collection_name)!
        println('Files in collection: ${files}')
    }
}
```

## Error Handling

DocTreeClient provides specific error types for different failure scenarios:

```v
pub enum DocTreeError {
    collection_not_found
    page_not_found
    file_not_found
    image_not_found
}
```

You can handle these errors using V's error handling mechanisms:

```v
// Example of error handling
page_content := client.get_page_content('my_collection', 'non_existent_page') or {
    if err.msg.contains('page_not_found') {
        println('The page does not exist')
        return
    }
    println('An error occurred: ${err}')
    return
}
```

## How It Works

DocTreeClient works with Redis as its backend storage:

1. The `doctree` module processes document collections and stores metadata in Redis
2. Collection paths are stored in the 'doctree:meta' hash
3. Page, file, and image paths within a collection are stored in 'doctree:{collection_name}' hashes
4. DocTreeClient provides methods to access this data and retrieve the actual content from the filesystem
