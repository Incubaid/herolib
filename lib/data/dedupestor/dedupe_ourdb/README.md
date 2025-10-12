# DedupeStore

DedupeStore is a content-addressable key-value store with built-in deduplication. It uses blake2b-160 content hashing to identify and deduplicate data, making it ideal for storing files or data blocks where the same content might appear multiple times.

## Features

- Content-based deduplication using blake2b-160 hashing
- Efficient storage using RadixTree for hash lookups
- Persistent storage using OurDB
- Maximum value size limit of 1MB
- Fast retrieval of data using content hash
- Automatic deduplication of identical content

## Usage

```v
import incubaid.herolib.data.dedupestor

// Create a new dedupestore
mut ds := dedupestor.new(
    path: 'path/to/store'
    reset: false // Set to true to reset existing data
)!

// Store some data
data := 'Hello, World!'.bytes()
hash := ds.store(data)!
println('Stored data with hash: ${hash}')

// Retrieve data using hash
retrieved := ds.get(hash)!
println('Retrieved data: ${retrieved.bytestr()}')

// Check if data exists
exists := ds.exists(hash)
println('Data exists: ${exists}')

// Attempting to store the same data again returns the same hash
same_hash := ds.store(data)!
assert hash == same_hash // True, data was deduplicated

```

## Implementation Details

DedupeStore uses two main components for storage:

1. **RadixTree**: Stores mappings from content hashes to data location IDs
2. **OurDB**: Stores the actual data blocks

When storing data:

1. The data is hashed using blake2b-160
2. If the hash exists in the RadixTree, the existing data location is returned
3. If the hash is new:
   - Data is stored in OurDB, getting a new location ID
   - Hash -> ID mapping is stored in RadixTree
   - The hash is returned

When retrieving data:

1. The RadixTree is queried with the hash to get the data location ID
2. The data is retrieved from OurDB using the ID

## Size Limits

- Maximum value size: 1MB
- Attempting to store larger values will result in an error

## the reference field

In the dedupestor system, the Reference struct is defined with two fields:

```v
pub struct Reference {
pub:
 owner u16
 id u32
}
```

The purpose of the id field in this context is to serve as an identifier within a specific owner's domain. Here's what each field represents:

owner (u16): Identifies which entity or system component "owns" or is referencing the data. This could represent different applications, users, or subsystems that are using the dedupestor.
id (u32): A unique identifier within that owner's domain. This allows each owner to have their own independent numbering system for referencing stored data.
Together, the {owner: 1, id: 100} combination creates a unique reference that:

Tracks which entities are referencing a particular piece of data
Allows the system to know when data can be safely deleted (when no references remain)
Provides a way for different components to maintain their own ID systems without conflicts
The dedupestor uses these references to implement a reference counting mechanism. When data is stored, a reference is attached to it. When all references to a piece of data are removed (via the delete method), the actual data can be safely deleted from storage.

This design allows for efficient deduplication - if the same data is stored multiple times with different references, it's only physically stored once, but the system keeps track of all the references to it.

## Testing

The module includes comprehensive tests covering:

- Basic store/retrieve operations
- Deduplication functionality
- Size limit enforcement
- Edge cases

Run tests with:

```bash
v test lib/data/dedupestor/
