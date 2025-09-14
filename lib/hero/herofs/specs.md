# HeroFS Specifications

This document provides detailed specifications for the HeroFS distributed filesystem implementation.

## Architecture Overview

HeroFS is built on top of HeroDB, which uses Redis as its storage backend. The filesystem is implemented as a collection of interconnected data structures that represent the various components of a filesystem:

1. **Fs** - Filesystem container
2. **FsDir** - Directories
3. **FsFile** - Files
4. **FsSymlink** - Symbolic links
5. **FsBlob** - Binary data chunks

All components inherit from the `Base` struct, which provides common fields like ID, name, description, timestamps, security policies, tags, and comments.

## Filesystem (Fs)

The `Fs` struct represents a filesystem as a top-level container:

```v
@[heap]
pub struct Fs {
	db.Base
pub mut:
	name        string
	group_id    u32 // Associated group for permissions
	root_dir_id u32 // ID of root directory
	quota_bytes u64 // Storage quota in bytes
	used_bytes  u64 // Current usage in bytes
}
```

### Key Features

- **Name-based identification**: Filesystems can be retrieved by name using efficient Redis hash sets
- **Quota management**: Each filesystem has a storage quota and tracks current usage
- **Root directory**: Each filesystem has a root directory ID that serves as the entry point
- **Group association**: Filesystems can be associated with groups for permission management

### Methods

- `new()`: Create a new filesystem instance
- `set()`: Save filesystem to database
- `get()`: Retrieve filesystem by ID
- `get_by_name()`: Retrieve filesystem by name
- `delete()`: Remove filesystem from database
- `exist()`: Check if filesystem exists
- `list()`: List all filesystems
- `increase_usage()`: Increase used bytes counter
- `decrease_usage()`: Decrease used bytes counter
- `check_quota()`: Verify if additional bytes would exceed quota

## Directory (FsDir)

The `FsDir` struct represents a directory in a filesystem:

```v
@[heap]
pub struct FsDir {
	db.Base
pub mut:
	name       string
	fs_id      u32   // Associated filesystem
	parent_id  u32   // Parent directory ID (0 for root)
}
```

### Key Features

- **Hierarchical structure**: Directories form a tree structure with parent-child relationships
- **Path-based identification**: Efficient lookup by filesystem ID, parent ID, and name
- **Children management**: Directories automatically track their children through Redis hash sets
- **Cross-filesystem isolation**: Directories are bound to a specific filesystem

### Methods

- `new()`: Create a new directory instance
- `set()`: Save directory to database and update indices
- `get()`: Retrieve directory by ID
- `delete()`: Remove directory (fails if it has children)
- `exist()`: Check if directory exists
- `list()`: List all directories
- `get_by_path()`: Retrieve directory by path components
- `list_by_filesystem()`: List directories in a filesystem
- `list_children()`: List child directories
- `has_children()`: Check if directory has children
- `rename()`: Rename directory
- `move()`: Move directory to a new parent

## File (FsFile)

The `FsFile` struct represents a file in a filesystem:

```v
@[heap]
pub struct FsFile {
	db.Base
pub mut:
	name        string
	fs_id       u32     // Associated filesystem
	directories []u32   // Directory IDs where this file exists
	blobs       []u32   // IDs of file content blobs
	size_bytes  u64    
	mime_type   string  // e.g., "image/png"
	checksum    string  // e.g., SHA256 checksum of the file
	accessed_at i64
	metadata    map[string]string // Custom metadata
}
```

### Key Features

- **Multiple directory associations**: Files can exist in multiple directories (similar to hard links in Linux)
- **Blob-based content**: File content is stored as references to FsBlob objects
- **Size tracking**: Files track their total size in bytes
- **MIME type support**: Files store their MIME type for content identification
- **Checksum verification**: Files can store checksums for integrity verification
- **Access timestamp**: Tracks when the file was last accessed
- **Custom metadata**: Files support custom key-value metadata

### Methods

- `new()`: Create a new file instance
- `set()`: Save file to database and update indices
- `get()`: Retrieve file by ID
- `delete()`: Remove file and update all indices
- `exist()`: Check if file exists
- `list()`: List all files
- `get_by_path()`: Retrieve file by directory and name
- `list_by_directory()`: List files in a directory
- `list_by_filesystem()`: List files in a filesystem
- `list_by_mime_type()`: List files by MIME type
- `append_blob()`: Add a new blob to the file
- `update_accessed()`: Update accessed timestamp
- `update_metadata()`: Update file metadata
- `rename()`: Rename file (affects all directories)
- `move()`: Move file to different directories

## Symbolic Link (FsSymlink)

The `FsSymlink` struct represents a symbolic link in a filesystem:

```v
@[heap]
pub struct FsSymlink {
	db.Base
pub mut:
	name        string
	fs_id       u32 // Associated filesystem
	parent_id   u32 // Parent directory ID
	target_id   u32 // ID of target file or directory
	target_type SymlinkTargetType
}

pub enum SymlinkTargetType {
	file
	directory
}
```

### Key Features

- **Target type specification**: Symlinks can point to either files or directories
- **Cross-filesystem protection**: Symlinks cannot point to targets in different filesystems
- **Referrer tracking**: Targets know which symlinks point to them
- **Broken link detection**: Symlinks can be checked for validity

### Methods

- `new()`: Create a new symbolic link instance
- `set()`: Save symlink to database and update indices
- `get()`: Retrieve symlink by ID
- `delete()`: Remove symlink and update all indices
- `exist()`: Check if symlink exists
- `list()`: List all symlinks
- `get_by_path()`: Retrieve symlink by parent directory and name
- `list_by_parent()`: List symlinks in a parent directory
- `list_by_filesystem()`: List symlinks in a filesystem
- `list_by_target()`: List symlinks pointing to a target
- `rename()`: Rename symlink
- `move()`: Move symlink to a new parent directory
- `redirect()`: Change symlink target
- `resolve()`: Get the target ID of a symlink
- `is_broken()`: Check if symlink target exists

## Binary Data Blob (FsBlob)

The `FsBlob` struct represents binary data chunks:

```v
@[heap]
pub struct FsBlob {
	db.Base
pub mut:
	hash        string // blake192 hash of content
	data        []u8   // Binary data (max 1MB)
	size_bytes  int    // Size in bytes
	created_at  i64
	mime_type   string // MIME type
	encoding    string // Encoding type
}
```

### Key Features

- **Content-based addressing**: Blobs are identified by their BLAKE3 hash (first 192 bits)
- **Size limit**: Blobs are limited to 1MB to ensure efficient storage and retrieval
- **Integrity verification**: Built-in hash verification for data integrity
- **MIME type and encoding**: Blobs store their content type information
- **Deduplication**: Identical content blobs are automatically deduplicated

### Methods

- `new()`: Create a new blob instance
- `set()`: Save blob to database (returns existing ID if content already exists)
- `get()`: Retrieve blob by ID
- `delete()`: Remove blob from database
- `exist()`: Check if blob exists
- `list()`: List all blobs
- `get_by_hash()`: Retrieve blob by content hash
- `exists_by_hash()`: Check if blob exists by content hash
- `verify_integrity()`: Verify blob data integrity against stored hash
- `calculate_hash()`: Calculate BLAKE3 hash of blob data

## Storage Mechanisms

HeroFS uses Redis hash sets extensively for efficient indexing and lookup:

### Filesystem Indices
- `fs:names` - Maps filesystem names to IDs
- `fsdir:paths` - Maps directory path components to IDs
- `fsdir:fs:${fs_id}` - Lists directories in a filesystem
- `fsdir:children:${dir_id}` - Lists children of a directory
- `fsfile:paths` - Maps file paths (directory:name) to IDs
- `fsfile:dir:${dir_id}` - Lists files in a directory
- `fsfile:fs:${fs_id}` - Lists files in a filesystem
- `fsfile:mime:${mime_type}` - Lists files by MIME type
- `fssymlink:paths` - Maps symlink paths (parent:name) to IDs
- `fssymlink:parent:${parent_id}` - Lists symlinks in a parent directory
- `fssymlink:fs:${fs_id}` - Lists symlinks in a filesystem
- `fssymlink:target:${target_type}:${target_id}` - Lists symlinks pointing to a target
- `fsblob:hashes` - Maps content hashes to blob IDs

### Data Serialization

All HeroFS components use the HeroLib encoder for serialization:

- Version tag (u8) is stored first
- All fields are serialized in a consistent order
- Deserialization follows the exact same order
- Type safety is maintained through V's type system

## Special Features

### Hard Links
Files can be associated with multiple directories through the `directories` field, allowing for hard link-like behavior.

### Deduplication
Blobs are automatically deduplicated based on their content hash. When creating a new blob with identical content to an existing one, the existing ID is returned.

### Quota Management
Filesystems track their storage usage and can enforce quotas to prevent overconsumption.

### Metadata Support
Files support custom metadata as key-value pairs, allowing for flexible attribute storage.

### Cross-Component Validation
When creating or modifying components, HeroFS validates references to other components:
- Directory parent must exist
- File directories must exist
- File blobs must exist
- Symlink parent must exist
- Symlink target must exist and match target type

## Security Model

HeroFS inherits the security model from HeroDB:
- Each component has a `securitypolicy` field referencing a SecurityPolicy object
- Components can have associated tags for categorization
- Components can have associated comments for documentation

## Performance Considerations

- All indices are stored as Redis hash sets for O(1) lookup performance
- Blob deduplication reduces storage requirements
- Multiple directory associations allow efficient file organization
- Content-based addressing enables easy integrity verification
- Factory pattern provides easy access to all filesystem components
