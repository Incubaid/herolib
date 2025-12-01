# DocTree Module

A lightweight document collection manager for V, inspired by doctree but simplified.

## Features

- **Simple Collection Scanning**: Automatically find collections marked with `.collection` files
- **Include Processing**: Process `!!include` actions to embed content from other pages
- **Easy Export**: Copy files to destination with organized structure
- **Optional Redis**: Store metadata in Redis for quick lookups and caching
- **Type-Safe Access**: Get pages, images, and files with error handling
- **Error Tracking**: Built-in error collection and reporting with deduplication


## Quick Start

put in .hero file and execute with hero or but shebang line on top of .hero script

**Scan Parameters:**

- `name` (optional, default: 'main') - DocTree instance name
- `path` (required when git_url not provided) - Directory path to scan
- `git_url` (alternative to path) - Git repository URL to clone/checkout
- `git_root` (optional when using git_url, default: ~/code) - Base directory for cloning
- `meta_path` (optional) - Directory to save collection metadata JSON
- `ignore` (optional) - List of directory names to skip during scan


**most basic example**

```heroscript
#!/usr/bin/env hero

!!doctree.scan git_url:"https://git.ourworld.tf/tfgrid/docs_tfgrid4/src/branch/main/collections/tests"

!!doctree.export 

```

put this in .hero file

## usage in herolib

```v
import incubaid.herolib.data.doctree

// Create a new DocTree
mut a := doctree.new(name: 'my_docs')!

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
mut a := doctree.new()!
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
content := page.content()!

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

DocTree supports simple include processing using `!!include` actions:

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
content := page.content()!
```


## Git Integration

DocTree automatically detects the git repository URL for each collection and stores it for reference. This allows users to easily navigate to the source for editing.

### Automatic Detection

When scanning collections, DocTree walks up the directory tree to find the `.git` directory and captures:
- **git_url**: The remote origin URL
- **git_branch**: The current branch

### Scanning from Git URL

You can scan collections directly from a git repository:

```heroscript
!!doctree.scan
    name: 'my_docs'
    git_url: 'https://github.com/myorg/docs.git'
    git_root: '~/code'  // optional, defaults to ~/code
```

The repository will be automatically cloned if it doesn't exist locally.

### Accessing Edit URLs

```v
mut page := doctree.page_get('guides:intro')!
edit_url := page.get_edit_url()!
println('Edit at: ${edit_url}')
// Output: Edit at: https://github.com/myorg/docs/edit/main/guides.md
```

### Export with Source Information

When exporting, the git URL is displayed:

```
Collection guides source: https://github.com/myorg/docs.git (branch: main)
```

This allows published documentation to link back to the source repository for contributions.
## Links

DocTree supports standard Markdown links with several formats for referencing pages within collections.

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

Check all links in your DocTree:

```v
mut a := doctree.new()!
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
mut a := doctree.new()!
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

### Export Directory Structure

When you export an DocTree, the directory structure is organized as:

$$\text{export\_dir}/
\begin{cases}
\text{content/} \\
\quad \text{collection\_name/} \\
\quad \quad \text{page1.md} \\
\quad \quad \text{page2.md} \\
\quad \quad \text{img/} & \text{(images)} \\
\quad \quad \quad \text{logo.png} \\
\quad \quad \quad \text{banner.jpg} \\
\quad \quad \text{files/} & \text{(other files)} \\
\quad \quad \quad \text{data.csv} \\
\quad \quad \quad \text{document.pdf} \\
\text{meta/} & \text{(metadata)} \\
\quad \text{collection\_name.json}
\end{cases}$$

- **Pages**: Markdown files directly in collection directory
- **Images**: Stored in `img/` subdirectory
- **Files**: Other resources stored in `files/` subdirectory
- **Metadata**: JSON files in `meta/` directory with collection information

## Redis Integration

DocTree uses Redis to store metadata about collections, pages, images, and files for fast lookups and caching.

### Redis Data Structure

When `redis: true` is set during export, DocTree stores:

1. **Collection Paths** - Hash: `doctree:path`
   - Key: collection name
   - Value: exported collection directory path

2. **Collection Contents** - Hash: `doctree:<collection_name>`
   - Pages: `page_name` → `page_name.md`
   - Images: `image_name.ext` → `img/image_name.ext`
   - Files: `file_name.ext` → `files/file_name.ext`

### Redis Usage Examples

```v
import incubaid.herolib.data.doctree
import incubaid.herolib.core.base

// Export with Redis metadata (default)
mut a := doctree.new(name: 'docs')!
a.scan(path: './docs')!
a.export(
    destination: './output'
    redis: true  // Store metadata in Redis
)!

// Later, retrieve metadata from Redis
mut context := base.context()!
mut redis := context.redis()!

// Get collection path
col_path := redis.hget('doctree:path', 'guides')!
println('Guides collection exported to: ${col_path}')

// Get page location
page_path := redis.hget('doctree:guides', 'introduction')!
println('Introduction page: ${page_path}')  // Output: introduction.md

// Get image location
img_path := redis.hget('doctree:guides', 'logo.png')!
println('Logo image: ${img_path}')  // Output: img/logo.png
```





## Saving Collections (Beta)

**Status:** Basic save functionality is implemented. Load functionality is work-in-progress.

### Saving to JSON

Save collection metadata to JSON files for archival or cross-tool compatibility:

```v
import incubaid.herolib.data.doctree

mut a := doctree.new(name: 'my_docs')!
a.scan(path: './docs')!

// Save all collections to a specified directory
// Creates: ${save_path}/${collection_name}.json
a.save('./metadata')!
```

### What Gets Saved

Each `.json` file contains:
- Collection metadata (name, path, git URL, git branch)
- All pages (with paths and collection references)
- All images and files (with paths and types)
- All errors (category, page_key, message, file)

### Storage Location

```
save_path/
├── collection1.json
├── collection2.json
└── collection3.json
```

## HeroScript Integration

DocTree integrates with HeroScript, allowing you to define DocTree operations in `.vsh` or playbook files.

### Using in V Scripts

Create a `.vsh` script to process DocTree operations:

```v
#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.playbook
import incubaid.herolib.data.doctree

// Define your HeroScript content
heroscript := "
!!doctree.scan path: './docs'

!!doctree.export destination: './output' include: true
"

// Create playbook from text
mut plbook := playbook.new(text: heroscript)!

// Execute doctree actions
doctree.play(mut plbook)!

println('DocTree processing complete!')
```

### Using in Playbook Files

Create a `docs.play` file:

```heroscript
!!doctree.scan
    name: 'main'
    path: '~/code/docs'

!!doctree.export
    destination: '~/code/output'
    reset: true
    include: true
    redis: true
```

Execute it:

```bash
vrun process_docs.vsh
```

Where `process_docs.vsh` contains:

```v
#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.playbook
import incubaid.herolib.core.playcmds

// Load and execute playbook
mut plbook := playbook.new(path: './docs.play')!
playcmds.run(mut plbook)!
```

### Error Handling

Errors are automatically collected and reported:

```heroscript
!!doctree.scan
 path: './docs'

# Errors will be printed during export
!!doctree.export
 destination: './output'
```

Errors are shown in the console:

```
Collection guides - Errors (2)
  [invalid_page_reference] [guides:intro]: Broken link to `guides:setup` at line 5
  [missing_include] [guides:advanced]: Included page `guides:examples` not found
```

### Auto-Export Behavior

If you use `!!doctree.scan` **without** an explicit `!!doctree.export`, DocTree will automatically export to the default location (current directory).

To disable auto-export, include an explicit (empty) export action or simply don't include any scan actions.

### Best Practices

1. **Always validate before export**: Use `!!doctree.validate` to catch broken links early
2. **Use named instances**: When working with multiple documentation sets, use the `name` parameter
3. **Enable Redis for production**: Use `redis: true` for web deployments to enable fast lookups
4. **Process includes during export**: Keep `include: true` to embed referenced content in exported files
## Roadmap - Not Yet Implemented

The following features are planned but not yet available:

- [ ] Load collections from `.collection.json` files
- [ ] Python API for reading collections
- [ ] `doctree.validate` playbook action
- [ ] `doctree.fix_links` playbook action
- [ ] Auto-save on collection modifications
- [ ] Collection version control