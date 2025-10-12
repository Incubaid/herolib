module graphdb

import incubaid.herolib.data.ourdb
import incubaid.herolib.data.cache { Cache, CacheConfig, new_cache }

// Node represents a vertex in the graph with properties and edge references
@[heap]
pub struct Node {
pub mut:
	id         u32               // Unique identifier
	properties map[string]string // Key-value properties
	node_type  string            // Type of node can e.g. refer to a object implementation e.g. a User, ...
	edges_out  []EdgeRef         // Outgoing edge references
	edges_in   []EdgeRef         // Incoming edge references
}

// Edge represents a connection between nodes with properties
@[heap]
pub struct Edge {
pub mut:
	id         u32               // Unique identifier
	from_node  u32               // Source node ID
	to_node    u32               // Target node ID
	edge_type  string            // Type of relationship
	properties map[string]string // Key-value properties
	weight     u16               // weight of the connection between the objects
}

// EdgeRef is a lightweight reference to an edge
@[heap]
pub struct EdgeRef {
pub mut:
	edge_id   u32    // Database ID of the edge
	edge_type string // Type of the edge relationship
}

// GraphDB represents the graph database
pub struct GraphDB {
mut:
	db         &ourdb.OurDB // Database for persistent storage
	node_cache &Cache[Node] // Cache for nodes
	edge_cache &Cache[Edge] // Cache for edges
}

pub struct NewArgs {
pub mut:
	path         string
	reset        bool
	cache_config CacheConfig = CacheConfig{} // Default cache configuration
}

// Creates a new graph database instance
pub fn new(args NewArgs) !&GraphDB {
	mut db := ourdb.new(
		path:             args.path
		record_size_max:  1024 * 4 // 4KB max record size
		incremental_mode: true
		reset:            args.reset
	)!

	// Create type-specific caches with provided config
	node_cache := new_cache[Node](args.cache_config)
	edge_cache := new_cache[Edge](args.cache_config)

	return &GraphDB{
		db:         &db
		node_cache: node_cache
		edge_cache: edge_cache
	}
}

// Creates a new node with the given properties
pub fn (mut gdb GraphDB) create_node(properties map[string]string) !u32 {
	mut node := Node{
		properties: properties
		edges_out:  []EdgeRef{}
		edges_in:   []EdgeRef{}
	}

	// Let OurDB assign the ID in incremental mode
	node_id := gdb.db.set(data: serialize_node(node))!

	// Update node with assigned ID and cache it
	node.id = node_id
	gdb.node_cache.set(node_id, &node)

	return node_id
}

// Creates an edge between two nodes
pub fn (mut gdb GraphDB) create_edge(from_id u32, to_id u32, edge_type string, properties map[string]string) !u32 {
	// Create the edge
	mut edge := Edge{
		from_node:  from_id
		to_node:    to_id
		edge_type:  edge_type
		properties: properties
	}

	// Let OurDB assign the ID in incremental mode
	edge_id := gdb.db.set(data: serialize_edge(edge))!

	// Update edge with assigned ID and cache it
	edge.id = edge_id
	gdb.edge_cache.set(edge_id, &edge)

	// Update source node's outgoing edges
	mut from_node := deserialize_node(gdb.db.get(from_id)!)!
	from_node.edges_out << EdgeRef{
		edge_id:   edge_id
		edge_type: edge_type
	}
	gdb.db.set(id: from_id, data: serialize_node(from_node))!
	gdb.node_cache.set(from_id, &from_node)

	// Update target node's incoming edges
	mut to_node := deserialize_node(gdb.db.get(to_id)!)!
	to_node.edges_in << EdgeRef{
		edge_id:   edge_id
		edge_type: edge_type
	}
	gdb.db.set(id: to_id, data: serialize_node(to_node))!
	gdb.node_cache.set(to_id, &to_node)

	return edge_id
}

// Gets a node by its ID
pub fn (mut gdb GraphDB) get_node(id u32) !Node {
	// Try cache first
	if cached_node := gdb.node_cache.get(id) {
		return *cached_node
	}

	// Load from database
	node_data := gdb.db.get(id)!
	node := deserialize_node(node_data)!

	// Cache the node
	gdb.node_cache.set(id, &node)

	return node
}

// Gets an edge by its ID
pub fn (mut gdb GraphDB) get_edge(id u32) !Edge {
	// Try cache first
	if cached_edge := gdb.edge_cache.get(id) {
		return *cached_edge
	}

	// Load from database
	edge_data := gdb.db.get(id)!
	edge := deserialize_edge(edge_data)!

	// Cache the edge
	gdb.edge_cache.set(id, &edge)

	return edge
}

// Updates a node's properties
pub fn (mut gdb GraphDB) update_node(id u32, properties map[string]string) ! {
	mut node := deserialize_node(gdb.db.get(id)!)!
	node.properties = properties.clone()

	// Update database
	gdb.db.set(id: id, data: serialize_node(node))!

	// Update cache
	gdb.node_cache.set(id, &node)
}

// Updates an edge's properties
pub fn (mut gdb GraphDB) update_edge(id u32, properties map[string]string) ! {
	mut edge := deserialize_edge(gdb.db.get(id)!)!
	edge.properties = properties.clone()

	// Update database
	gdb.db.set(id: id, data: serialize_edge(edge))!

	// Update cache
	gdb.edge_cache.set(id, &edge)
}

// Deletes a node and all its edges
pub fn (mut gdb GraphDB) delete_node(id u32) ! {
	node := deserialize_node(gdb.db.get(id)!)!

	// Delete outgoing edges
	for edge_ref in node.edges_out {
		gdb.delete_edge(edge_ref.edge_id)!
	}

	// Delete incoming edges
	for edge_ref in node.edges_in {
		gdb.delete_edge(edge_ref.edge_id)!
	}

	// Delete from database
	gdb.db.delete(id)!

	// Remove from cache
	gdb.node_cache.remove(id)
}

// Deletes an edge and updates connected nodes
pub fn (mut gdb GraphDB) delete_edge(id u32) ! {
	edge := deserialize_edge(gdb.db.get(id)!)!

	// Update source node
	mut from_node := deserialize_node(gdb.db.get(edge.from_node)!)!
	for i, edge_ref in from_node.edges_out {
		if edge_ref.edge_id == id {
			from_node.edges_out.delete(i)
			break
		}
	}
	gdb.db.set(id: edge.from_node, data: serialize_node(from_node))!
	gdb.node_cache.set(edge.from_node, &from_node)

	// Update target node
	mut to_node := deserialize_node(gdb.db.get(edge.to_node)!)!
	for i, edge_ref in to_node.edges_in {
		if edge_ref.edge_id == id {
			to_node.edges_in.delete(i)
			break
		}
	}
	gdb.db.set(id: edge.to_node, data: serialize_node(to_node))!
	gdb.node_cache.set(edge.to_node, &to_node)

	// Delete from database and cache
	gdb.db.delete(id)!
	gdb.edge_cache.remove(id)
}

// Queries nodes by property value
pub fn (mut gdb GraphDB) query_nodes_by_property(key string, value string) ![]Node {
	mut nodes := []Node{}
	mut next_id := gdb.db.get_next_id()!

	// Process each ID up to next_id
	for id := u32(0); id < next_id; id++ {
		// Try to get from cache first
		if cached := gdb.node_cache.get(id) {
			if prop_value := cached.properties[key] {
				if prop_value == value {
					nodes << *cached
				}
			}
			continue
		}

		// Not in cache, try to get from database
		raw_data := gdb.db.get(id) or { continue }
		mut node := deserialize_node(raw_data) or { continue }

		// Cache the node for future use
		gdb.node_cache.set(id, &node)

		// Check if this node matches the query
		if prop_value := node.properties[key] {
			if prop_value == value {
				nodes << node
			}
		}
	}

	return nodes
}

// Gets all edges between two nodes
pub fn (mut gdb GraphDB) get_edges_between(from_id u32, to_id u32) ![]Edge {
	mut from_node := if cached := gdb.node_cache.get(from_id) {
		*cached
	} else {
		node := deserialize_node(gdb.db.get(from_id)!)!
		gdb.node_cache.set(from_id, &node)
		node
	}

	mut edges := []Edge{}
	for edge_ref in from_node.edges_out {
		edge_data := if cached := gdb.edge_cache.get(edge_ref.edge_id) {
			*cached
		} else {
			mut edge := deserialize_edge(gdb.db.get(edge_ref.edge_id)!)!
			gdb.edge_cache.set(edge_ref.edge_id, &edge)
			edge
		}

		if edge_data.to_node == to_id {
			edges << edge_data
		}
	}

	return edges
}

// Gets all nodes connected to a given node by edge type
pub fn (mut gdb GraphDB) get_connected_nodes(id u32, edge_type string, direction string) ![]Node {
	mut start_node := if cached := gdb.node_cache.get(id) {
		*cached
	} else {
		node := deserialize_node(gdb.db.get(id)!)!
		gdb.node_cache.set(id, &node)
		node
	}

	mut connected_nodes := []Node{}

	if direction in ['out', 'both'] {
		for edge_ref in start_node.edges_out {
			if edge_ref.edge_type == edge_type {
				edge_data := if cached := gdb.edge_cache.get(edge_ref.edge_id) {
					*cached
				} else {
					mut edge := deserialize_edge(gdb.db.get(edge_ref.edge_id)!)!
					gdb.edge_cache.set(edge_ref.edge_id, &edge)
					edge
				}

				mut target_node := if cached := gdb.node_cache.get(edge_data.to_node) {
					*cached
				} else {
					node := deserialize_node(gdb.db.get(edge_data.to_node)!)!
					gdb.node_cache.set(edge_data.to_node, &node)
					node
				}
				connected_nodes << target_node
			}
		}
	}

	if direction in ['in', 'both'] {
		for edge_ref in start_node.edges_in {
			if edge_ref.edge_type == edge_type {
				edge_data := if cached := gdb.edge_cache.get(edge_ref.edge_id) {
					*cached
				} else {
					mut edge := deserialize_edge(gdb.db.get(edge_ref.edge_id)!)!
					gdb.edge_cache.set(edge_ref.edge_id, &edge)
					edge
				}

				mut source_node := if cached := gdb.node_cache.get(edge_data.from_node) {
					*cached
				} else {
					node := deserialize_node(gdb.db.get(edge_data.from_node)!)!
					gdb.node_cache.set(edge_data.from_node, &node)
					node
				}
				connected_nodes << source_node
			}
		}
	}

	return connected_nodes
}
