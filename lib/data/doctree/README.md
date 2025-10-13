# Doctree Module

The primary goal of this module is to transform structured document collections into a format suitable for various outputs. It handles the complexities of finding collections, loading their content, processing includes, definitions, and macros, and exporting the final result while managing assets like images and files.

## Key Concepts

* **Tree:** The central component (`doctree.Tree`) that holds one or more `Collection` instances. It orchestrates the scanning, processing, and exporting of all contained collections.
* **Collection:** A directory that is marked as a collection by the presence of a `.collection` file. A collection groups related documents (pages, images, files) and can have its own configuration defined within the `.collection` file.
* **.collection file:** A file placed in a directory to designate it as a collection. This file can optionally contain parameters (using the `paramsparser` format) such as a custom name for the collection.

## How it Works (Workflow)

The typical workflow involves creating a `Tree`, scanning for collections, and then exporting the processed content.å

1. **Create Tree:** Initialize a `doctree.Tree` instance using `doctree.new()`.
2. **Scan:** Use the `tree.scan()`  method, providing a path to a directory or a Git repository URL. The scanner recursively looks for directories containing a `.collection` file.
3. **Load Content:** For each identified collection, the module loads its content, including markdown pages, images, and other files.
4. **Process Content:** The loaded content is processed. This includes handling definitions, includes (content from other files), and macros (dynamic content generation or transformation).
5. **Generate Output Paths:** The module determines the final paths for all processed files and assets in the destination directory.
6. **Export:** The `tree.export()` method writes the processed content and assets to the specified destination directory, maintaining the desired structure.

## Usage (For Developers)

Here's a basic example of how to use the `doctree` module in your V project:

```v
import incubaid.herolib.data.doctree
// 1. Create a new Tree instance
mut tree := doctree.new(name: 'my_documentation')!

// 2. Scan a directory containing your collections
// Replace './docs' with the actual path to your document collections
tree.scan(path: './docs')!

// use from URL
//git_url   string
//git_reset bool
//git_pull  bool
tree.scan(git_url: 'https://git.threefold.info/tfgrid/docs_tfgrid4/src/branch/main/collections')!

// 3. Export the processed content to a destination directory
// Replace './output' with your desired output path
// if redis then the metadata will be put in redis
tree.export(destination: './output', redis:true)!

println('Documentation successfully exported to ./output')

```

## Structure of a Collection

A collection is a directory containing a `.collection` file. Inside a collection directory, you would typically organize your content like this:

```
my_collection/
├── .collection
├── page1.md
├── page2.md
├── images/
│   ├── image1.png
│   └── image2.jpg
└── files/
    ├── document.pdf
    └── data.csv
```

Markdown files (`.md`) are treated as pages.

## use Play

```heroscript

!!doctree.collection name:"my_local_docs" path:"./docs"

!!doctree.collection name:"tfgrid_docs"
    git_url:"https://git.threefold.info/tfgrid/docs_tfgrid4/src/branch/main/collections"
    git_reset: true
    git_pull: true

//is optional, if not specified then will be at ${os.home_dir()}/hero/var/doctree/main
!!doctree.export name: "my_local_docs", destination: "/tmp/1" exclude_errors:0 reset:1
```

## Redis Structure

when using the export redis:true argument, which is default

in redis we will find

```bash
#redis hsets:
doctree:$collectionname $pagename   $rel_path_in_collection
doctree:$collectionname $filename.$ext  $rel_path_in_collection
doctree:meta            $collectionname     $collectionpath_on_disk
```
