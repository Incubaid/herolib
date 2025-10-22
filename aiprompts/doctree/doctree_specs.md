# Doctree Export Specification

## Overview

The `doctree` module in `lib/data/doctree` is responsible for processing and exporting documentation trees. This involves taking a structured representation of documentation (collections, pages, images, files) and writing it to a specified file system destination. Additionally, it leverages Redis to store metadata about the exported documentation, facilitating quick lookups and integration with other systems.

## Key Components

### `lib/data/doctree/export.v`

This file defines the main `export` function for the `Tree` object. It orchestrates the overall export process:

- Takes `TreeExportArgs` which includes parameters like `destination`, `reset` (to clear destination), `keep_structure`, `exclude_errors`, `toreplace` (for regex replacements), `concurrent` (for parallel processing), and `redis` (to control Redis metadata storage).
- Processes definitions, includes, actions, and macros within the `Tree`.
- Generates file paths for pages, images, and other files.
- Iterates through `Collection` objects within the `Tree` and calls their respective `export` methods, passing down the `redis` flag.

### `lib/data/doctree/collection/export.v`

This file defines the `export` function for the `Collection` object. This is where the actual file system writing and Redis interaction for individual collections occur:

- Takes `CollectionExportArgs` which includes `destination`, `file_paths`, `reset`, `keep_structure`, `exclude_errors`, `replacer`, and the `redis` flag.
- Creates a `.collection` file in the destination directory with basic collection information.
- **Redis Integration**:
  - Obtains a Redis client using `base.context().redis()`.
  - Stores the collection's destination path in Redis using `redis.hset('doctree:path', 'collection_name', 'destination_path')`.
  - Calls `export_pages`, `export_files`, `export_images`, and `export_linked_pages` which all interact with Redis if the `redis` flag is true.
- **`export_pages`**:
  - Processes page links and handles not-found errors.
  - Writes markdown content to the destination file system.
  - Stores page metadata in Redis: `redis.hset('doctree:collection_name', 'page_name', 'page_file_name.md')`.
- **`export_files` and `export_images`**:
  - Copies files and images to the destination directory (e.g., `img/`).
  - Stores file/image metadata in Redis: `redis.hset('doctree:collection_name', 'file_name', 'img/file_name.ext')`.
- **`export_linked_pages`**:
  - Gathers linked pages within the collection.
  - Writes a `.linkedpages` file.
  - Stores linked pages file metadata in Redis: `redis.hset('doctree:collection_name', 'linkedpages', 'linkedpages_file_name.md')`.

## Link between Redis and Export

The `doctree` export process uses Redis as a metadata store. When the `redis` flag is set to `true` (which is the default), the export functions populate Redis with key-value pairs that map collection names, page names, file names, and image names to their respective paths and file names within the exported documentation structure.

This Redis integration serves as a quick lookup mechanism for other applications or services that might need to access or reference the exported documentation. Instead of traversing the file system, these services can query Redis to get the location of specific documentation elements.

## Is Export Needed?

Yes, the export functionality is crucial for making the processed `doctree` content available outside the internal `doctree` representation.

- **File System Export**: The core purpose of the export is to write the documentation content (markdown files, images, other assets) to a specified directory. This is essential for serving the documentation via a web server, integrating with static site generators (like Docusaurus, as suggested by other files in the project), or simply providing a browsable version of the documentation.
- **Redis Metadata**: While the file system export is fundamental, the Redis metadata storage is an important complementary feature. It provides an efficient way for other systems to programmatically discover and locate documentation assets. If there are downstream applications that rely on this Redis metadata for navigation, search, or content delivery, then the Redis part of the export is indeed needed. If no such applications exist or are planned, the `redis` flag can be set to `false` to skip this step, but the file system export itself remains necessary for external consumption of the documentation.
