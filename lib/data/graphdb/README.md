# GraphDB

A lightweight, efficient graph database implementation in V that supports property graphs with nodes and edges. It provides both in-memory caching and persistent storage capabilities.

## Features

- Property Graph Model
  - Nodes with key-value properties
  - Typed edges with properties
  - Bidirectional edge traversal
- Persistent Storage
  - Automatic data persistence
  - Efficient serialization
- Memory-Efficient Caching
  - LRU caching for nodes and edges
  - Configurable cache sizes
- Rich Query Capabilities
  - Property-based node queries
  - Edge-based node traversal
  - Relationship type filtering
- CRUD Operations
  - Create, read, update, and delete nodes
  - Manage relationships between nodes
  - Update properties dynamically

## Installation

GraphDB is part of the HeroLib library. Include it in your V project:

```v
import incubaid.herolib.data.graphdb
```

## Basic Usage

Here's a simple example demonstrating core functionality:

```v
import incubaid.herolib.data.graphdb

fn main() {
    // Create a new graph database
    mut gdb := graphdb.new(path: '/tmp/mydb', reset: true)!

    // Create nodes
    user_id := gdb.create_node({
        'name': 'John',
        'age': '30',
        'city': 'London'
    })!

    company_id := gdb.create_node({
        'name': 'TechCorp',
        'industry': 'Technology'
    })!

    // Create relationship
    gdb.create_edge(user_id, company_id, 'WORKS_AT', {
        'role': 'Developer',
        'since': '2022'
    })!

    // Query nodes by property
    london_users := gdb.query_nodes_by_property('city', 'London')!
    
    // Find connected nodes
    workplaces := gdb.get_connected_nodes(user_id, 'WORKS_AT', 'out')!
}
```

## API Reference

### Creating a Database

```v
// Create new database instance
struct NewArgs {
    path         string        // Storage path
    reset        bool          // Clear existing data
    cache_config CacheConfig   // Optional cache configuration
}
db := graphdb.new(NewArgs{...})!
```

### Node Operations

```v
// Create node
node_id := db.create_node(properties: map[string]string)!

// Get node
node := db.get_node(id: u32)!

// Update node
db.update_node(id: u32, properties: map[string]string)!

// Delete node (and connected edges)
db.delete_node(id: u32)!

// Query nodes by property
nodes := db.query_nodes_by_property(key: string, value: string)!
```

### Edge Operations

```v
// Create edge
edge_id := db.create_edge(from_id: u32, to_id: u32, edge_type: string, properties: map[string]string)!

// Get edge
edge := db.get_edge(id: u32)!

// Update edge
db.update_edge(id: u32, properties: map[string]string)!

// Delete edge
db.delete_edge(id: u32)!

// Get edges between nodes
edges := db.get_edges_between(from_id: u32, to_id: u32)!
```

### Graph Traversal

```v
// Get connected nodes
// direction can be 'in', 'out', or 'both'
nodes := db.get_connected_nodes(id: u32, edge_type: string, direction: string)!
```

## Data Model

### Node Structure

```v
struct Node {
    id         u32                // Unique identifier
    properties map[string]string  // Key-value properties
    node_type  string            // Type of node
    edges_out  []EdgeRef         // Outgoing edge references
    edges_in   []EdgeRef         // Incoming edge references
}
```

### Edge Structure

```v
struct Edge {
    id         u32                // Unique identifier
    from_node  u32               // Source node ID
    to_node    u32               // Target node ID
    edge_type  string            // Type of relationship
    properties map[string]string  // Key-value properties
    weight     u16               // Edge weight
}
```

## Performance Considerations

- The database uses LRU caching for both nodes and edges to improve read performance
- Persistent storage is handled efficiently through the underlying OurDB implementation
- Edge references are stored in both source and target nodes for efficient traversal
- Property queries perform full scans - consider indexing needs for large datasets

## Example Use Cases

- Social Networks: Modeling user relationships and interactions
- Knowledge Graphs: Representing connected information and metadata
- Organization Charts: Modeling company structure and relationships
- Recommendation Systems: Building relationship-based recommendation engines
