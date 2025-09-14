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
import freeflowuniverse.herolib.hero.herofs

mut fs_factory := herofs.new()!
```

### Creating a Filesystem

```v
fs_id := fs_factory.fs.set(fs_factory.fs.new(
	name: 'my_filesystem'
	quota_bytes: 1000000000 // 1GB quota
)!)!
```

### Working with Directories

```v
// Create root directory
root_dir_id := fs_factory.fs_dir.set(fs_factory.fs_dir.new(
	name: 'root'
	fs_id: fs_id
	parent_id: 0
)!)!

// Create subdirectory
sub_dir_id := fs_factory.fs_dir.set(fs_factory.fs_dir.new(
	name: 'documents'
	fs_id: fs_id
	parent_id: root_dir_id
)!)!
```

### Working with Blobs

```v
// Create a blob with binary data
blob_id := fs_factory.fs_blob.set(fs_factory.fs_blob.new(
	data: content_bytes
	mime_type: 'text/plain'
)!)!
```

### Working with Files

```v
// Create a file
file_id := fs_factory.fs_file.set(fs_factory.fs_file.new(
	name: 'example.txt'
	fs_id: fs_id
	directories: [root_dir_id]
	blobs: [blob_id]
)!)!
```

### Working with Symbolic Links

```v
// Create a symbolic link to a file
symlink_id := fs_factory.fs_symlink.set(fs_factory.fs_symlink.new(
	name: 'example_link.txt'
	fs_id: fs_id
	parent_id: root_dir_id
	target_id: file_id
	target_type: .file
)!)!
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
