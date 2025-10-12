# HeroFS - Distributed Filesystem for HeroLib

HeroFS is a distributed filesystem implementation built on top of HeroDB (Redis-based storage). It provides a virtual filesystem with support for files, directories, symbolic links, and binary data blobs.

## Overview

HeroFS implements a filesystem structure where:

- **Fs**: Represents a filesystem as a top-level container
- **FsDir**: Represents directories within a filesystem
- **FsFile**: Represents files with support for multiple directory associations
- **FsSymlink**: Represents symbolic links pointing to files or directories
- **FsBlob**: Represents binary data chunks (up to 1MB) used as file content

## Features

- Distributed storage using Redis
- Support for files, directories, and symbolic links
- Blob-based file content storage with integrity verification
- Multiple directory associations for files (similar to hard links)
- Filesystem quotas and usage tracking
- Metadata support for files
- Efficient lookup mechanisms using Redis hash sets

## Installation

HeroFS is part of HeroLib and is automatically available when using HeroLib.

## Usage

To use HeroFS, you need to create a filesystem factory:

```v
import incubaid.herolib.hero.herofs

mut fs_factory := herofs.new()!
```

### Creating a Filesystem

```v
mut fs := fs_factory.fs.new(
 name: 'my_filesystem'
 quota_bytes: 1000000000 // 1GB quota
)!
fs = fs_factory.fs.set(fs)!
fs_id := fs.id
```

### Working with Directories

```v
// Create root directory
mut root_dir := fs_factory.fs_dir.new(
 name: 'root'
 fs_id: fs_id
 parent_id: 0
)!
root_dir_id := fs_factory.fs_dir.set(root_dir)!

// Create subdirectory
mut sub_dir := fs_factory.fs_dir.new(
 name: 'documents'
 fs_id: fs_id
 parent_id: root_dir_id
)!
sub_dir_id := fs_factory.fs_dir.set(sub_dir)!
```

### Working with Blobs

```v
// Create a blob with binary data
mut blob := fs_factory.fs_blob.new(
 data: content_bytes
 mime_type: 'text/plain'
)!
blob_id := fs_factory.fs_blob.set(blob)!
```

### Working with Files

```v
// Create a file
mut file := fs_factory.fs_file.new(
 name: 'example.txt'
 fs_id: fs_id
 directories: [root_dir_id]
 blobs: [blob_id]
)!
file_id := fs_factory.fs_file.set(file)!
```

### Working with Symbolic Links

```v
// Create a symbolic link to a file
mut symlink := fs_factory.fs_symlink.new(
 name: 'example_link.txt'
 fs_id: fs_id
 parent_id: root_dir_id
 target_id: file_id
 target_type: .file
)!
symlink_id := fs_factory.fs_symlink.set(symlink)!
```

## API Reference

The HeroFS module provides the following main components:

- `FsFactory` - Main factory for accessing all filesystem components
- `DBFs` - Filesystem operations
- `DBFsDir` - Directory operations
- `DBFsFile` - File operations
- `DBFsSymlink` - Symbolic link operations
- `DBFsBlob` - Binary data blob operations

Each component provides CRUD operations and specialized methods for filesystem management.

## Examples

Check the `examples/hero/herofs/` directory for detailed usage examples.
