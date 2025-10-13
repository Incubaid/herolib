# Database Filesystem Implementation (vfs_db)

A virtual filesystem implementation that uses OurDB as its storage backend, providing a complete filesystem interface with database-backed storage.

## Features

- Persistent storage in OurDB database
- Full support for files, directories, and symlinks
- Transactional operations
- Structured metadata storage
- Hierarchical filesystem structure
- Thread-safe operations

## Implementation Details

### Structure

```
vfs_db/
├── factory.v               # VFS factory implementation
├── vfs_implementation.v    # Core VFS interface implementation
├── vfs.v                  # DatabaseVFS type definition
├── model_file.v           # File type implementation
├── model_directory.v      # Directory type implementation
├── model_symlink.v        # Symlink type implementation
├── model_fsentry.v        # Common FSEntry interface
├── metadata.v             # Metadata structure
├── encoder.v              # Data encoding utilities
├── vfs_directory.v        # Directory operations
├── vfs_getters.v         # Common getter methods
└── *_test.v              # Implementation tests
```

### Key Components

- `DatabaseVFS`: Main implementation struct

```v
pub struct DatabaseVFS {
pub mut:
    root_id          u32    
    block_size       u32    
    data_dir         string 
    metadata_dir     string 
    db_data          &Database
    last_inserted_id u32
}
```

- `FSEntry` implementations:

```v
pub type FSEntry = Directory | File | Symlink
```

### Data Storage

#### Metadata Structure

```v
struct Metadata {
    id          u32    // Unique identifier
    name        string // Entry name
    file_type   FileType
    size        u64
    created_at  i64    // Unix timestamp
    modified_at i64
    accessed_at i64
    mode        u32    // Permissions
    owner       string
    group       string
}
```

#### Database Interface

```v
pub interface Database {
mut:
    get(id u32) ![]u8
    set(ourdb.OurDBSetArgs) !u32
    delete(id u32)!
}
```

## Usage

```v
import incubaid.herolib.vfs.vfs_db

// Create separate databases for data and metadata
mut db_data := ourdb.new(
    path: os.join_path(test_data_dir, 'data')
    incremental_mode: false
)!

mut db_metadata := ourdb.new(
    path: os.join_path(test_data_dir, 'metadata')
    incremental_mode: false
)!

// Create VFS with separate databases for data and metadata
mut fs := new(mut db_data, mut db_metadata)!

// Create directory structure
fs.dir_create('documents')!
fs.dir_create('documents/reports')!

// Create and write files
fs.file_create('documents/reports/q1.txt')!
fs.file_write('documents/reports/q1.txt', 'Q1 Report Content'.bytes())!

// Create symbolic links
fs.link_create('documents/reports/q1.txt', 'documents/latest.txt')!

// List directory contents
entries := fs.dir_list('documents')!
for entry in entries {
    println('${entry.get_path()} (${entry.get_metadata().size} bytes)')
}

// Clean up
fs.destroy()!

```

## Implementation Notes

1. Data Encoding:
   - Version byte for format compatibility
   - Entry type indicator
   - Entry-specific binary data
   - Efficient storage format

2. Thread Safety:
   - Mutex protection for concurrent access
   - Atomic operations
   - Clear ownership semantics

3. Error Handling:
   - Descriptive error messages
   - Proper error propagation
   - Recovery mechanisms
   - Consistency checks

## Limitations

- Performance overhead compared to direct filesystem access
- Database size grows with filesystem usage
- Requires proper database maintenance
- Limited by database backend capabilities

## Testing

The implementation includes tests for:

- Basic operations (create, read, write, delete)
- Directory operations and traversal
- Symlink handling
- Concurrent access
- Error conditions
- Edge cases
- Data consistency

Run tests with:

```bash
v test vfs/vfs_db/
```

## Future Improvements

1. Performance Optimizations:
   - Entry caching
   - Batch operations
   - Improved traversal algorithms

2. Feature Additions:
   - Extended attributes
   - Access control lists
   - Quota management
   - Transaction support

3. Robustness:
   - Automated recovery
   - Consistency verification
   - Better error handling
   - Backup/restore capabilities
