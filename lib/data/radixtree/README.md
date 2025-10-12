# Radix Tree Implementation

A radix tree (also known as a patricia trie or radix trie) is a space-optimized tree data structure that enables efficient string key operations. This implementation provides a persistent radix tree backed by OurDB for durable storage.

## Key Features

- Efficient prefix-based key operations
- Persistent storage using OurDB backend
- Memory-efficient storage of strings with common prefixes
- Support for binary values
- Thread-safe operations through OurDB

## How It Works

### Data Structure

The radix tree is composed of nodes where:

- Each node stores a segment of a key (not just a single character)
- Nodes can have multiple children, each representing a different branch
- Leaf nodes contain the actual values
- Each node is persisted in OurDB with a unique ID

```v
struct Node {
mut:
    key_segment string    // The segment of the key stored at this node
    value      []u8      // Value stored at this node (empty if not a leaf)
    children   []NodeRef // References to child nodes
    is_leaf    bool      // Whether this node is a leaf node
}
```

### OurDB Integration

The radix tree uses OurDB as its persistent storage backend:

- Each node is serialized and stored as a record in OurDB
- Node references use OurDB record IDs
- The tree maintains a root node ID for traversal
- Node serialization includes version tracking for format evolution

### Key Operations

#### Set (formerly Insertion)

1. Traverse the tree following matching prefixes
2. Split nodes when partial matches are found
3. Create new nodes for unmatched segments
4. Update node values and references in OurDB

#### Get (formerly Search)

1. Start from the root node
2. Follow child nodes whose key segments match the search key
3. Return the value if an exact match is found at a leaf node

#### List (formerly Search by Prefix)

1. Start from the root node
2. Find all keys that start with the given prefix
3. Return a list of matching keys

#### GetAll

1. Find all keys that start with the given prefix using List
2. Retrieve the value for each matching key
3. Return a list of values for all matching keys

#### Deletion

1. Locate the node containing the key
2. Remove the value and leaf status
3. Clean up empty nodes if necessary
4. Update parent references

## Usage Example

```v
import incubaid.herolib.data.radixtree

// Create a new radix tree
mut tree := radixtree.new('/path/to/storage')!

// Set key-value pairs
tree.set('hello', 'world'.bytes())!
tree.set('help', 'me'.bytes())!

// Get values by key
value := tree.get('hello')! // Returns 'world' as bytes
println(value.bytestr()) // Prints: world

// List keys by prefix
keys := tree.list('hel')! // Returns ['hello', 'help']

// Get all values by prefix
values := tree.getall('hel')! // Returns ['world'.bytes(), 'me'.bytes()]

// Delete keys
tree.delete('help')!
```

## Implementation Details

### Node Serialization

Nodes are serialized in a compact binary format:

```
[Version(1B)][KeySegment][ValueLength(2B)][Value][ChildrenCount(2B)][Children][IsLeaf(1B)]
```

Where each child is stored as:

```
[KeyPart][NodeID(4B)]
```

### Space Optimization

The radix tree optimizes space usage by:

1. Sharing common prefixes between keys
2. Storing only key segments at each node instead of complete keys
3. Merging nodes with single children when possible
4. Using OurDB's efficient storage and retrieval mechanisms

### Performance Characteristics

- Search: O(k) where k is the key length
- Insert: O(k) for new keys, may require node splitting
- Delete: O(k) plus potential node cleanup
- Space: O(n) where n is the total length of all keys

## Relationship with OurDB

This radix tree implementation leverages OurDB's features:

- Persistent storage with automatic file management
- Record-based storage with unique IDs
- Data integrity through CRC32 checksums
- Configurable record sizes
- Automatic file size management

The integration provides:

- Durability: All tree operations are persisted
- Consistency: Tree state is maintained across restarts
- Efficiency: Leverages OurDB's optimized storage
- Scalability: Handles large datasets through OurDB's file management

## Use Cases

Radix trees are particularly useful for:

- Prefix-based searching
- IP routing tables
- Dictionary implementations
- Auto-complete systems
- File system paths
- Any application requiring efficient string key operations with persistence
