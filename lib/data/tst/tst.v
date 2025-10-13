module tst

import incubaid.herolib.data.ourdb

// Represents a node in the ternary search tree
struct Node {
mut:
	character        u8   // The character stored at this nodexs
	is_end_of_string bool // Flag indicating if this node represents the end of a key
	value            []u8 // The value associated with the key (if this node is the end of a key)
	left_id          u32  // Database ID for left child (character < node.character)
	middle_id        u32  // Database ID for middle child (character == node.character)
	right_id         u32  // Database ID for right child (character > node.character)
}

// TST represents a ternary search tree data structure
@[heap]
pub struct TST {
mut:
	db      &ourdb.OurDB // Database for persistent storage
	root_id u32          // Database ID of the root node
}

@[params]
pub struct NewArgs {
pub mut:
	path  string
	reset bool
}

// Creates a new ternary search tree with the specified database path
pub fn new(args NewArgs) !TST {
	println('Creating new TST with path: ${args.path}, reset: ${args.reset}')
	mut db := ourdb.new(
		path:             args.path
		record_size_max:  1024 * 1024 // 1MB
		incremental_mode: true
		reset:            args.reset
	)!

	mut root_id := u32(1) // First ID in ourdb is now 1 instead of 0

	if db.get_next_id()! == 1 {
		// Create a new root node if the database is empty
		// We'll use a null character (0) for the root node
		println('Creating new root node')
		root := Node{
			character:        0
			is_end_of_string: false
			value:            []u8{}
			left_id:          0
			middle_id:        0
			right_id:         0
		}
		root_id = db.set(data: serialize_node(root))!
		println('Root node created with ID: ${root_id}')
		assert root_id == 1 // First ID is now 1
	} else {
		// Database already exists, just get the root node
		println('Database already exists, getting root node')
		root_data := db.get(1)! // Get root node with ID 1
		root := deserialize_node(root_data)!
		println('Root node retrieved: character=${root.character}, is_end=${root.is_end_of_string}, left=${root.left_id}, middle=${root.middle_id}, right=${root.right_id}')
		root_id = 1 // Ensure we're using ID 1 for the root
	}

	return TST{
		db:      &db
		root_id: root_id
	}
}

// Sets a key-value pair in the tree
pub fn (mut self TST) set(key string, value []u8) ! {
	normalized_key := namefix(key)
	println('Setting key: "${key}" (normalized: "${normalized_key}")')

	if normalized_key.len == 0 {
		return error('Empty key not allowed')
	}

	// If the tree is empty, create a root node
	if self.root_id == 0 {
		println('Tree is empty, creating root node')
		root := Node{
			character:        0
			is_end_of_string: false
			value:            []u8{}
			left_id:          0
			middle_id:        0
			right_id:         0
		}
		self.root_id = self.db.set(data: serialize_node(root))!
		println('Root node created with ID: ${self.root_id}')
	}

	// Insert the key-value pair
	mut last_node_id := self.insert_recursive(self.root_id, normalized_key, 0, value)!
	println('Key "${normalized_key}" inserted to node ${last_node_id}')

	// Make sure the last node is marked as end of string with the value
	if last_node_id != 0 {
		node_data := self.db.get(last_node_id)!
		mut node := deserialize_node(node_data)!

		// Ensure this node is marked as the end of a string
		if !node.is_end_of_string {
			println('Setting node ${last_node_id} as end of string')
			node.is_end_of_string = true
			node.value = value
			self.db.set(id: last_node_id, data: serialize_node(node))!
		}
	}

	println('Key "${normalized_key}" inserted successfully')
}

// Recursive helper function for insertion
fn (mut self TST) insert_recursive(node_id u32, key string, pos int, value []u8) !u32 {
	// Check for position out of bounds
	if pos >= key.len {
		println('Position ${pos} is out of bounds for key "${key}"')
		return error('Position out of bounds')
	}

	// If we've reached the end of the tree, create a new node
	if node_id == 0 {
		println('Creating new node for character: ${key[pos]} (${key[pos].ascii_str()}) at position ${pos}')

		// Create a node for this character
		new_node := Node{
			character:        key[pos]
			is_end_of_string: pos == key.len - 1
			value:            if pos == key.len - 1 { value.clone() } else { []u8{} }
			left_id:          0
			middle_id:        0
			right_id:         0
		}
		new_id := self.db.set(data: serialize_node(new_node))!
		println('New node created with ID: ${new_id}, character: ${key[pos]} (${key[pos].ascii_str()}), is_end: ${pos == key.len - 1}')

		// If this is the last character in the key, we're done
		if pos == key.len - 1 {
			return new_id
		}

		// Otherwise, create the next node in the sequence and link to it
		next_id := self.insert_recursive(0, key, pos + 1, value)!

		// Update the middle link
		node_data := self.db.get(new_id)!
		mut updated_node := deserialize_node(node_data)!
		updated_node.middle_id = next_id
		self.db.set(id: new_id, data: serialize_node(updated_node))!

		return new_id
	}

	// Get the current node with error handling
	node_data := self.db.get(node_id) or {
		println('Failed to get node data for ID ${node_id}')
		return error('Node retrieval error: ${err}')
	}

	mut node := deserialize_node(node_data) or {
		println('Failed to deserialize node with ID ${node_id}')
		return error('Node deserialization error: ${err}')
	}

	println('Node ${node_id}: character=${node.character} (${node.character.ascii_str()}), is_end=${node.is_end_of_string}, left=${node.left_id}, middle=${node.middle_id}, right=${node.right_id}')

	// Compare the current character with the node's character
	if key[pos] < node.character {
		println('Going left for character: ${key[pos]} (${key[pos].ascii_str()}) < ${node.character} (${node.character.ascii_str()})')
		// Go left
		node.left_id = self.insert_recursive(node.left_id, key, pos, value)!
		self.db.set(id: node_id, data: serialize_node(node))!
	} else if key[pos] > node.character {
		println('Going right for character: ${key[pos]} (${key[pos].ascii_str()}) > ${node.character} (${node.character.ascii_str()})')
		// Go right
		node.right_id = self.insert_recursive(node.right_id, key, pos, value)!
		self.db.set(id: node_id, data: serialize_node(node))!
	} else {
		// Equal - go middle
		if pos == key.len - 1 {
			println('End of key reached, setting is_end_of_string=true')
			// We've reached the end of the key
			node.is_end_of_string = true
			node.value = value
			self.db.set(id: node_id, data: serialize_node(node))!
		} else {
			println('Going middle for next character: ${key[pos + 1]} (${key[pos + 1].ascii_str()})')
			// Move to the next character in the key
			node.middle_id = self.insert_recursive(node.middle_id, key, pos + 1, value)!
			self.db.set(id: node_id, data: serialize_node(node))!
		}
	}

	return node_id
}

// Gets a value by key from the tree
pub fn (mut self TST) get(key string) ![]u8 {
	normalized_key := namefix(key)
	println('Getting key: "${key}" (normalized: "${normalized_key}")')

	if normalized_key.len == 0 {
		return error('Empty key not allowed')
	}

	if self.root_id == 0 {
		return error('Tree is empty')
	}

	return self.search_recursive(self.root_id, normalized_key, 0)!
}

// Very simple recursive search with explicit structure to make the compiler happy
fn (mut self TST) search_recursive(node_id u32, key string, pos int) ![]u8 {
	// Base cases
	if node_id == 0 {
		println('Node ID is 0, key not found')
		return error('Key not found')
	}

	if pos >= key.len {
		println('Position ${pos} out of bounds for key "${key}"')
		return error('Key not found - position out of bounds')
	}

	// Get the node
	node_data := self.db.get(node_id) or {
		println('Failed to get node ${node_id}')
		return error('Node not found in database')
	}

	node := deserialize_node(node_data) or {
		println('Failed to deserialize node ${node_id}')
		return error('Failed to deserialize node')
	}

	println('Searching node ${node_id}: char=${node.character}, pos=${pos}, key_char=${key[pos]}')

	mut result := []u8{}

	// Left branch
	if key[pos] < node.character {
		println('Going left')
		result = self.search_recursive(node.left_id, key, pos) or { return error(err.str()) }
		return result
	}

	// Right branch
	if key[pos] > node.character {
		println('Going right')
		result = self.search_recursive(node.right_id, key, pos) or { return error(err.str()) }
		return result
	}

	// Character matches
	println('Character match')

	// At end of key
	if pos == key.len - 1 {
		if node.is_end_of_string {
			println('Found key')
			// Copy the value
			for i in 0 .. node.value.len {
				result << node.value[i]
			}
			return result
		} else {
			println('Character match but not end of string')
			return error('Key not found - not marked as end of string')
		}
	}

	// Not at end of key, go to middle
	if node.middle_id == 0 {
		println('No middle child')
		return error('Key not found - no middle child')
	}

	println('Going to middle child')
	result = self.search_recursive(node.middle_id, key, pos + 1) or { return error(err.str()) }
	return result
}

// Deletes a key from the tree
pub fn (mut self TST) delete(key string) ! {
	normalized_key := namefix(key)
	println('Deleting key: "${key}" (normalized: "${normalized_key}")')

	if normalized_key.len == 0 {
		return error('Empty key not allowed')
	}

	if self.root_id == 0 {
		return error('Tree is empty')
	}

	self.delete_recursive(self.root_id, normalized_key, 0)!
	println('Key "${normalized_key}" deleted successfully')
}

// Recursive helper function for deletion
fn (mut self TST) delete_recursive(node_id u32, key string, pos int) !bool {
	if node_id == 0 {
		println('Node ID is 0, key not found')
		return error('Key not found')
	}

	// Check for position out of bounds
	if pos >= key.len {
		println('Position ${pos} is out of bounds for key "${key}"')
		return error('Key not found - position out of bounds')
	}

	// Get the current node with error handling
	node_data := self.db.get(node_id) or {
		println('Failed to get node data for ID ${node_id}')
		return error('Node retrieval error: ${err}')
	}

	mut node := deserialize_node(node_data) or {
		println('Failed to deserialize node with ID ${node_id}')
		return error('Node deserialization error: ${err}')
	}

	println('Deleting from node ${node_id}: character=${node.character} (${node.character.ascii_str()}), is_end=${node.is_end_of_string}, left=${node.left_id}, middle=${node.middle_id}, right=${node.right_id}, pos=${pos}')
	mut deleted := false

	if key[pos] < node.character {
		println('Going left: ${key[pos]} (${key[pos].ascii_str()}) < ${node.character} (${node.character.ascii_str()})')
		// Go left
		if node.left_id == 0 {
			println('Left child is null, key not found')
			return error('Key not found')
		}

		deleted = self.delete_recursive(node.left_id, key, pos)!
		if deleted && node.left_id != 0 {
			// Check if the left child has been deleted
			if _ := self.db.get(node.left_id) {
				// Child still exists
				println('Left child still exists')
			} else {
				// Child has been deleted
				println('Left child has been deleted, updating node')
				node.left_id = 0
				self.db.set(id: node_id, data: serialize_node(node))!
			}
		}
	} else if key[pos] > node.character {
		println('Going right: ${key[pos]} (${key[pos].ascii_str()}) > ${node.character} (${node.character.ascii_str()})')
		// Go right
		if node.right_id == 0 {
			println('Right child is null, key not found')
			return error('Key not found')
		}

		deleted = self.delete_recursive(node.right_id, key, pos)!
		if deleted && node.right_id != 0 {
			// Check if the right child has been deleted
			if _ := self.db.get(node.right_id) {
				// Child still exists
				println('Right child still exists')
			} else {
				// Child has been deleted
				println('Right child has been deleted, updating node')
				node.right_id = 0
				self.db.set(id: node_id, data: serialize_node(node))!
			}
		}
	} else {
		// Equal
		println('Character matches: ${key[pos]} (${key[pos].ascii_str()}) == ${node.character} (${node.character.ascii_str()})')
		if pos == key.len - 1 {
			// We've reached the end of the key
			if node.is_end_of_string {
				// Found the key
				println('End of key reached and is_end_of_string=true, found the key')
				if node.left_id == 0 && node.middle_id == 0 && node.right_id == 0 {
					// Node has no children, delete it
					println('Node has no children, deleting it')
					self.db.delete(node_id)!
					return true
				} else {
					// Node has children, just mark it as not end of string
					println('Node has children, marking it as not end of string')
					node.is_end_of_string = false
					node.value = []u8{}
					self.db.set(id: node_id, data: serialize_node(node))!
					return false
				}
			} else {
				println('End of key reached but is_end_of_string=false, key not found')
				return error('Key not found')
			}
		} else {
			// Move to the next character in the key
			println('Moving to next character: ${key[pos + 1]} (${key[pos + 1].ascii_str()})')
			if node.middle_id == 0 {
				println('Middle child is null, key not found')
				return error('Key not found')
			}

			deleted = self.delete_recursive(node.middle_id, key, pos + 1)!
			if deleted && node.middle_id != 0 {
				// Check if the middle child has been deleted
				if _ := self.db.get(node.middle_id) {
					// Child still exists
					println('Middle child still exists')
				} else {
					// Child has been deleted
					println('Middle child has been deleted, updating node')
					node.middle_id = 0
					self.db.set(id: node_id, data: serialize_node(node))!
				}
			}
		}
	}

	// If this node has no children and is not the end of a string, delete it
	if node.left_id == 0 && node.middle_id == 0 && node.right_id == 0 && !node.is_end_of_string {
		println('Node has no children and is not end of string, deleting it')
		self.db.delete(node_id)!
		return true
	}

	return deleted
}
