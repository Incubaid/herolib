module radixtree

import freeflowuniverse.herolib.data.ourdb
// import freeflowuniverse.herolib.ui.console

// Represents a node in the radix tree
struct Node {
mut:
	key_segment string    // The segment of the key stored at this node
	value       []u8      // Value stored at this node (empty if not a leaf)
	children    []NodeRef // References to child nodes
	is_leaf     bool      // Whether this node is a leaf node
}

// Reference to a node in the database
struct NodeRef {
mut:
	key_part string // The key segment for this child
	node_id  u32    // Database ID of the node
}

// PathInfo tracks information about nodes in the deletion path
struct PathInfo {
	node_id       u32    // ID of the parent node
	edge_to_child string // Edge label from parent to child
	child_id      u32    // ID of the child node
}

// RadixTree represents a radix tree data structure
@[heap]
pub struct RadixTree {
mut:
	db      &ourdb.OurDB // Database for persistent storage
	root_id u32          // Database ID of the root node
}

pub struct NewArgs {
pub mut:
	path  string
	reset bool
}

// Creates a new radix tree with the specified database path
pub fn new(args NewArgs) !RadixTree {
	mut db := ourdb.new(
		path:             args.path
		record_size_max:  1024 * 4 // 4KB max record size
		incremental_mode: true
		reset:            args.reset
	)!

	mut root_id := u32(1) // First ID in ourdb is now 1 instead of 0
	// console.print_debug('Debug: Initializing root node')
	if db.get_next_id()! == 1 {
		// console.print_debug('Debug: Creating new root node')
		root := Node{
			key_segment: ''
			value:       []u8{}
			children:    []NodeRef{}
			is_leaf:     false
		}
		root_id = db.set(data: serialize_node(root))!
		// console.print_debug('Debug: Created root node with ID ${root_id}')
		assert root_id == 1 // First ID is now 1
	} else {
		// console.print_debug('Debug: Using existing root node')
		root_data := db.get(1)! // Get root node with ID 1
		// root_node :=
		deserialize_node(root_data)!
		// console.print_debug('Debug: Root node has ${root_node.children.len} children')
	}

	return RadixTree{
		db:      &db
		root_id: root_id
	}
}

// Sets a key-value pair in the tree
pub fn (mut rt RadixTree) set(key string, value []u8) ! {
	mut current_id := rt.root_id
	mut offset := 0

	for {
		mut node := deserialize_node(rt.db.get(current_id)!)!
		rem := key[offset..]

		if rem.len == 0 {
			// turn current node into leaf (value replace)
			node.is_leaf = true
			node.value = value
			rt.db.set(id: current_id, data: serialize_node(node))!
			return
		}

		mut best_idx := -1
		mut best_cp := 0
		for i, ch in node.children {
			cp := get_common_prefix(rem, ch.key_part).len
			if cp > 0 {
				best_idx = i
				best_cp = cp
				break // with proper invariant there can be only one candidate
			}
		}

		if best_idx == -1 {
			// no overlap at all -> add new leaf child
			new_leaf := Node{
				key_segment: rem
				value:       value
				children:    []NodeRef{}
				is_leaf:     true
			}
			new_id := rt.db.set(data: serialize_node(new_leaf))!
			// reload parent (avoid stale) then append child
			mut parent := deserialize_node(rt.db.get(current_id)!)!
			parent.children << NodeRef{
				key_part: rem
				node_id:  new_id
			}
			// keep children sorted lexicographically
			sort_children(mut parent.children)
			rt.db.set(id: current_id, data: serialize_node(parent))!
			return
		}

		// we have overlap with child
		mut chref := node.children[best_idx]
		child_part := chref.key_part
		if best_cp == child_part.len {
			// child_part is fully consumed by rem -> descend
			current_id = chref.node_id
			offset += best_cp
			continue
		}

		// need to split the existing child
		// new intermediate node with edge = common prefix
		common := get_common_prefix(rem, child_part)
		child_suffix := child_part[common.len..]
		rem_suffix := rem[common.len..]

		mut old_child := deserialize_node(rt.db.get(chref.node_id)!)!

		// new node representing the existing child's suffix
		split_child := Node{
			key_segment: child_suffix
			value:       old_child.value
			children:    old_child.children
			is_leaf:     old_child.is_leaf
		}
		split_child_id := rt.db.set(data: serialize_node(split_child))!

		// build the intermediate
		mut intermediate := Node{
			key_segment: '' // not used at traversal time
			value:       []u8{}
			children:    [
				NodeRef{
					key_part: child_suffix
					node_id:  split_child_id
				},
			]
			is_leaf:     false
		}

		// if our new key ends exactly at the common prefix, the intermediate becomes a leaf
		if rem_suffix.len == 0 {
			intermediate.is_leaf = true
			intermediate.value = value
		} else {
			// add second child for our new key's remainder
			new_leaf := Node{
				key_segment: rem_suffix
				value:       value
				children:    []NodeRef{}
				is_leaf:     true
			}
			new_leaf_id := rt.db.set(data: serialize_node(new_leaf))!
			intermediate.children << NodeRef{
				key_part: rem_suffix
				node_id:  new_leaf_id
			}
			// keep children sorted
			sort_children(mut intermediate.children)
		}

		// write intermediate, get id
		interm_id := rt.db.set(data: serialize_node(intermediate))!

		// replace the matched child on parent with the intermediate (edge = common)
		node.children[best_idx] = NodeRef{
			key_part: common
			node_id:  interm_id
		}
		rt.db.set(id: current_id, data: serialize_node(node))!
		return
	}
}

// Gets a value by key from the tree
pub fn (mut rt RadixTree) get(key string) ![]u8 {
	mut current_id := rt.root_id
	mut offset := 0

	for {
		node := deserialize_node(rt.db.get(current_id)!)!
		rem := key[offset..]

		if rem.len == 0 {
			// reached end of key
			if node.is_leaf {
				return node.value
			}
			return error('Key not found')
		}

		// binary search for matching child (since children are sorted)
		child_idx := rt.find_child_with_prefix(node.children, rem)
		if child_idx == -1 {
			return error('Key not found')
		}

		child := node.children[child_idx]
		common_prefix := get_common_prefix(rem, child.key_part)

		if common_prefix.len != child.key_part.len {
			// partial match - key doesn't exist
			return error('Key not found')
		}

		current_id = child.node_id
		offset += child.key_part.len
	}

	return error('Key not found')
}

// Binary search helper to find child with matching prefix
fn (rt RadixTree) find_child_with_prefix(children []NodeRef, key string) int {
	if children.len == 0 || key.len == 0 {
		return -1
	}

	// For now, use linear search but with proper common prefix logic
	// TODO: implement true binary search based on first character
	for i, child in children {
		if get_common_prefix(key, child.key_part).len > 0 {
			return i
		}
	}
	return -1
}

// Updates the value at a given key prefix, preserving the prefix while replacing the remainder
pub fn (mut rt RadixTree) update(prefix string, new_value []u8) ! {
	mut current_id := rt.root_id
	mut offset := 0

	// Handle empty prefix case
	if prefix.len == 0 {
		return error('Empty prefix not allowed')
	}

	for offset < prefix.len {
		node := deserialize_node(rt.db.get(current_id)!)!

		mut found := false
		for child in node.children {
			if prefix[offset..].starts_with(child.key_part) {
				if offset + child.key_part.len == prefix.len {
					// Found exact prefix match
					mut child_node := deserialize_node(rt.db.get(child.node_id)!)!
					if child_node.is_leaf {
						// Update the value
						child_node.value = new_value
						rt.db.set(id: child.node_id, data: serialize_node(child_node))!
						return
					}
				}
				current_id = child.node_id
				offset += child.key_part.len
				found = true
				break
			}
		}

		if !found {
			return error('Prefix not found')
		}
	}

	return error('Prefix not found')
}

// Deletes a key from the tree
pub fn (mut rt RadixTree) delete(key string) ! {
	mut current_id := rt.root_id
	mut offset := 0
	mut path := []PathInfo{} // Track node IDs and edge labels in the path

	// Handle empty key case
	if key.len == 0 {
		mut root_node := deserialize_node(rt.db.get(current_id)!)!
		if !root_node.is_leaf {
			return error('Key not found')
		}
		root_node.is_leaf = false
		root_node.value = []u8{}
		rt.db.set(id: current_id, data: serialize_node(root_node))!
		rt.maybe_compress_with_path(current_id, path)!
		return
	}

	// Find the node to delete
	for offset < key.len {
		node := deserialize_node(rt.db.get(current_id)!)!

		mut found := false
		for child in node.children {
			common_prefix := get_common_prefix(key[offset..], child.key_part)
			if common_prefix.len > 0 {
				if common_prefix.len == child.key_part.len {
					// Full match with child edge
					path << PathInfo{
						node_id:       current_id
						edge_to_child: child.key_part
						child_id:      child.node_id
					}
					current_id = child.node_id
					offset += child.key_part.len
					found = true
					break
				} else {
					// Partial match - key doesn't exist
					return error('Key not found')
				}
			}
		}

		if !found {
			return error('Key not found')
		}
	}

	// Check if the target node is actually a leaf
	mut target_node := deserialize_node(rt.db.get(current_id)!)!
	if !target_node.is_leaf {
		return error('Key not found')
	}

	// If the node has children, just mark it as non-leaf
	if target_node.children.len > 0 {
		target_node.is_leaf = false
		target_node.value = []u8{}
		rt.db.set(id: current_id, data: serialize_node(target_node))!
		rt.maybe_compress_with_path(current_id, path)!
		return
	}

	// Node has no children, remove it from parent
	if path.len > 0 {
		parent_info := path.last()
		parent_id := parent_info.node_id
		mut parent_node := deserialize_node(rt.db.get(parent_id)!)!

		// Remove the child reference
		for i, child in parent_node.children {
			if child.node_id == current_id {
				parent_node.children.delete(i)
				break
			}
		}

		rt.db.set(id: parent_id, data: serialize_node(parent_node))!
		rt.db.delete(current_id)!

		// Compress the parent if needed
		rt.maybe_compress_with_path(parent_id, path[..path.len - 1])!
	} else {
		// This is the root node, just mark as non-leaf
		target_node.is_leaf = false
		target_node.value = []u8{}
		rt.db.set(id: current_id, data: serialize_node(target_node))!
	}
}

// Helper function for path compression after deletion (legacy version)
fn (mut rt RadixTree) maybe_compress(node_id u32) ! {
	rt.maybe_compress_with_path(node_id, []PathInfo{})!
}

// Helper function for path compression after deletion with path information
fn (mut rt RadixTree) maybe_compress_with_path(node_id u32, path []PathInfo) ! {
	mut node := deserialize_node(rt.db.get(node_id)!)!
	if node.is_leaf {
		return
	}
	if node.children.len != 1 {
		return
	}

	ch := node.children[0]
	mut child_node := deserialize_node(rt.db.get(ch.node_id)!)!

	// merge child into node by lifting child's children and value
	node.is_leaf = child_node.is_leaf
	node.value = child_node.value
	node.children = child_node.children.clone()

	rt.db.set(id: node_id, data: serialize_node(node))!
	rt.db.delete(ch.node_id)!

	// Update the parent's edge to include the compressed path
	if path.len > 0 {
		// Find the parent that points to this node
		for i := path.len - 1; i >= 0; i-- {
			if path[i].child_id == node_id {
				parent_id := path[i].node_id
				mut parent_node := deserialize_node(rt.db.get(parent_id)!)!

				// Update the edge label to include the compressed segment
				for j, child in parent_node.children {
					if child.node_id == node_id {
						parent_node.children[j].key_part += ch.key_part
						rt.db.set(id: parent_id, data: serialize_node(parent_node))!
						break
					}
				}
				break
			}
		}
	}
}

// Lists all keys with a given prefix
pub fn (mut rt RadixTree) list(prefix string) ![]string {
	mut result := []string{}

	if prefix.len == 0 {
		rt.collect_all_keys(rt.root_id, '', mut result)!
		return result
	}

	node_info := rt.find_node_for_prefix_with_path(prefix) or {
		// prefix not found, return empty result
		return result
	}
	rt.collect_all_keys(node_info.node_id, node_info.path, mut result)!

	// Filter results to only include keys that actually start with the prefix
	mut filtered_result := []string{}
	for key in result {
		if key.starts_with(prefix) {
			filtered_result << key
		}
	}

	return filtered_result
}

struct NodePathInfo {
	node_id u32
	path    string
}

// Find the node where a prefix ends and return both node ID and the actual path to that node
fn (mut rt RadixTree) find_node_for_prefix_with_path(prefix string) !NodePathInfo {
	mut current_id := rt.root_id
	mut offset := 0
	mut current_path := ''

	for offset < prefix.len {
		node := deserialize_node(rt.db.get(current_id)!)!
		rem := prefix[offset..]

		mut found := false
		for child in node.children {
			common_prefix := get_common_prefix(rem, child.key_part)
			cp_len := common_prefix.len

			if cp_len == 0 {
				continue
			}

			if cp_len == child.key_part.len {
				// child edge is fully consumed by prefix
				current_id = child.node_id
				current_path += child.key_part
				offset += cp_len
				found = true
				break
			} else if cp_len == rem.len {
				// prefix ends inside this edge; we need to collect keys from this subtree
				// but only those that actually start with the full prefix
				return NodePathInfo{
					node_id: current_id
					path:    current_path
				}
			} else {
				// diverged -> no matches
				return error('Prefix not found')
			}
		}

		if !found {
			return error('Prefix not found')
		}
	}

	return NodePathInfo{
		node_id: current_id
		path:    current_path
	}
}

// Find the node where a prefix ends (or the subtree root for that prefix)
fn (mut rt RadixTree) find_node_for_prefix(prefix string) !u32 {
	info := rt.find_node_for_prefix_with_path(prefix)!
	return info.node_id
}

// Helper function to recursively collect all keys under a node
fn (mut rt RadixTree) collect_all_keys(node_id u32, current_path string, mut result []string) ! {
	node := deserialize_node(rt.db.get(node_id)!)!

	// If this node is a leaf, add its path to the result
	if node.is_leaf {
		result << current_path
	}

	// Recursively collect keys from all children
	for child in node.children {
		child_path := current_path + child.key_part
		rt.collect_all_keys(child.node_id, child_path, mut result)!
	}
}

// Helper function to get the common prefix of two strings
// Gets all values for keys with a given prefix
pub fn (mut rt RadixTree) getall(prefix string) ![][]u8 {
	// Get all matching keys
	keys := rt.list(prefix)!

	// Get values for each key
	mut values := [][]u8{}
	for key in keys {
		if value := rt.get(key) {
			values << value
		}
	}

	return values
}

// Helper function to get the common prefix of two strings
fn get_common_prefix(a string, b string) string {
	mut i := 0
	for i < a.len && i < b.len && a[i] == b[i] {
		i++
	}
	return a[..i]
}

// Helper function to sort children lexicographically
fn sort_children(mut children []NodeRef) {
	children.sort_with_compare(fn (a &NodeRef, b &NodeRef) int {
		return if a.key_part < b.key_part {
			-1
		} else if a.key_part > b.key_part {
			1
		} else {
			0
		}
	})
}
