# OurDB Module

OurDB is a lightweight, efficient key-value database implementation in V that provides data persistence with history tracking capabilities. It's designed for scenarios where you need fast key-value storage with the ability to track changes over time.

## Usage Example

```v
import incubaid.herolib.data.ourdb

// Configure and create a new database instance
mut db := ourdb.new(
    path: '/tmp/mydb',              // storage directory
    record_nr_max: 16777216 - 1,    // max number of records (default)
    record_size_max: 1024 * 4,      // max record size (4KB default)
    file_size: 500 * (1 << 20),     // file size (500MB default)
    incremental_mode: true          // enable auto-incrementing IDs (default)
)!

// Store data with auto-incrementing ID (incremental mode)
id := db.set(data: 'Hello World'.bytes())!

// Store data with specific ID (is an update)
id2 := db.set(id: 1, data: 'Hello Again'.bytes())!

// Retrieve data
data := db.get(1)! // Returns []u8

// Get history
history := db.get_history(1, 5)! // Get last 5 versions

// Delete data
db.delete(1)!
```

## Features

- Efficient key-value storage
- History tracking for values
- Data integrity verification using CRC32
- Support for multiple backend files
- Configurable record sizes and counts
- Memory and disk-based lookup tables
- Optional incremental ID mode

## Configuration Options

```v
struct OurDBConfig {
    record_nr_max   u32 = 16777216 - 1    // max size of records
    record_size_max u32 = 1024 * 4        // max size in bytes of a record (4KB default)
    file_size       u32 = 500 * (1 << 20) // file size (500MB default)
    path            string                 // directory where we will store the DB
    incremental_mode bool = true          // enable auto-incrementing IDs
}
```

## Architecture

OurDB consists of three main components working together in a layered architecture:

### 1. Frontend (db.v)

- Provides the public API for database operations
- Handles high-level operations (set, get, delete, history)
- Coordinates between lookup and backend components
- Supports both key-value and incremental ID modes

### 2. Lookup Table (lookup.v)

- Maps keys to physical locations in the backend storage
- Supports both memory and disk-based lookup tables
- Automatically optimizes key sizes based on database configuration
- Handles sparse data efficiently
- Provides next ID generation for incremental mode

### 3. Backend Storage (backend.v)

- Manages the actual data storage in files
- Handles data integrity with CRC32 checksums
- Supports multiple file backends for large datasets
- Implements the low-level read/write operations

## File Structure

- `db.v`: Frontend interface providing the public API
- `lookup.v`: Core lookup table implementation
- `lookup_location.v`: Location tracking implementation
- `lookup_location_test.v`: Location tracking tests
- `lookup_id_test.v`: ID generation tests
- `lookup_test.v`: General lookup table tests
- `backend.v`: Low-level data storage implementation
- `factory.v`: Database initialization and configuration
- `db_test.v`: Test suite for verifying functionality

## How It Works

1. **Frontend Operations**
   - When you call `set()`, the frontend:
     1. In incremental mode, generates the next ID or uses provided ID
     2. Gets the storage location from the lookup table
     3. Passes the data to the backend for storage
     4. Updates the lookup table with any new location

2. **Lookup Table**
   - Maintains a mapping between keys and physical locations
   - Optimizes key size based on:
     - Total number of records (affects address space)
     - Record size and count (determines file splitting)
   - Supports incremental ID generation
   - Persists lookup data to disk for recovery

3. **Backend Storage**
   - Stores data in one or multiple files
   - Each record includes:
     - Data size
     - CRC32 checksum
     - Previous record location (for history)
     - Actual data
   - Automatically handles file selection and management

## Implementation Details

### Record Format

Each record in the backend storage includes:

- 2 bytes: Data size
- 4 bytes: CRC32 checksum
- 6 bytes: Previous record location
- N bytes: Actual data

### Lookup Table Optimization

The lookup table automatically optimizes its key size based on the database configuration:

- 2 bytes: For databases with < 65,536 records
- 3 bytes: For databases with < 16,777,216 records
- 4 bytes: For databases with < 4,294,967,296 records
- 6 bytes: For large databases requiring multiple files

### File Management

- Supports splitting data across multiple files when needed
- Each file is limited to 500MB by default (configurable)
- Automatic file selection based on record location
- Files are created as needed with format: `${path}/${file_nr}.db`
- Lookup table state is persisted in `${path}/lookup_dump.db`
