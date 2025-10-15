module tst

import incubaid.herolib.data.ourdb

// Lists all keys with a given prefix
pub fn (mut self TST) list(prefix string) ![]string {
	normalized_prefix := namefix(prefix)
	println('Listing keys with prefix: "${prefix}" (normalized: "${normalized_prefix}")')
	mut result := []string{}

	// Handle empty prefix case - will return all keys
	if normalized_prefix.len == 0 {
		println('Empty prefix, collecting all keys')
		self.collect_all_keys(self.root_id, '', mut result)!
		println('Found ${result.len} keys: ${result}')
		return result
	}

	// Find the prefix node first
	result_info := self.navigate_to_prefix(self.root_id, normalized_prefix, 0)

	if !result_info.found {
		println('Prefix node not found for "${normalized_prefix}"')
		return result // Empty result
	}

	println('Found node for prefix "${normalized_prefix}" at node ${result_info.node_id}, collecting keys')

	// Collect all keys from the subtree rooted at the prefix node
	self.collect_keys_with_prefix(result_info.node_id, result_info.prefix, mut result)!

	println('Found ${result.len} keys with prefix "${normalized_prefix}": ${result}')
	return result
}

// Result struct for prefix navigation
struct PrefixSearchResult {
	found   bool
	node_id u32
	prefix  string
}

// Navigate to the node corresponding to a prefix
fn (mut self TST) navigate_to_prefix(node_id u32, prefix string, pos int) PrefixSearchResult {
	// Base case: no node or out of bounds
	if node_id == 0 || pos >= prefix.len {
		return PrefixSearchResult{
			found:   false
			node_id: 0
			prefix:  ''
		}
	}

	// Get node
	node_data := self.db.get(node_id) or {
		return PrefixSearchResult{
			found:   false
			node_id: 0
			prefix:  ''
		}
	}

	node := deserialize_node(node_data) or {
		return PrefixSearchResult{
			found:   false
			node_id: 0
			prefix:  ''
		}
	}

	println('Navigating node ${node_id}: char=${node.character} (${node.character.ascii_str()}), pos=${pos}, prefix_char=${prefix[pos]} (${prefix[pos].ascii_str()})')

	// Character comparison
	if prefix[pos] < node.character {
		// Go left
		println('Going left')
		return self.navigate_to_prefix(node.left_id, prefix, pos)
	} else if prefix[pos] > node.character {
		// Go right
		println('Going right')
		return self.navigate_to_prefix(node.right_id, prefix, pos)
	} else {
		// Character match
		println('Character match found')

		// Check if we're at the end of the prefix
		if pos == prefix.len - 1 {
			println('Reached end of prefix at node ${node_id}')
			// Return the exact prefix string that was passed in
			return PrefixSearchResult{
				found:   true
				node_id: node_id
				prefix:  prefix
			}
		}

		// Not at end of prefix, check middle child
		if node.middle_id == 0 {
			println('No middle child, prefix not found')
			return PrefixSearchResult{
				found:   false
				node_id: 0
				prefix:  ''
			}
		}

		// Continue to middle child with next character
		return self.navigate_to_prefix(node.middle_id, prefix, pos + 1)
	}
}

// Collect all keys in a subtree that have a given prefix
fn (mut self TST) collect_keys_with_prefix(node_id u32, prefix string, mut result []string) ! {
	if node_id == 0 {
		return
	}

	// Get node
	node_data := self.db.get(node_id) or { return }
	node := deserialize_node(node_data) or { return }

	println('Collecting from node ${node_id}, char=${node.character} (${node.character.ascii_str()}), prefix="${prefix}"')

	// If this node is an end of string and it's not the root, we found a key
	if node.is_end_of_string && node.character != 0 {
		// The prefix may already contain this node's character
		if prefix.len == 0 || prefix[prefix.len - 1] != node.character {
			println('Found complete key: "${prefix}${node.character.ascii_str()}"')
			result << prefix + node.character.ascii_str()
		} else {
			println('Found complete key: "${prefix}"')
			result << prefix
		}
	}

	// Recursively search all children
	if node.left_id != 0 {
		self.collect_keys_with_prefix(node.left_id, prefix, mut result)!
	}

	// For middle child, we need to add this node's character to the prefix
	if node.middle_id != 0 {
		mut next_prefix := prefix
		if node.character != 0 { // Skip root node
			// Only add the character if it's not already at the end of the prefix
			if prefix.len == 0 || prefix[prefix.len - 1] != node.character {
				next_prefix += node.character.ascii_str()
			}
		}
		self.collect_keys_with_prefix(node.middle_id, next_prefix, mut result)!
	}

	if node.right_id != 0 {
		self.collect_keys_with_prefix(node.right_id, prefix, mut result)!
	}
}

// Collect all keys in the tree
fn (mut self TST) collect_all_keys(node_id u32, prefix string, mut result []string) ! {
	if node_id == 0 {
		return
	}

	// Get node
	node_data := self.db.get(node_id) or { return }
	node := deserialize_node(node_data) or { return }

	// Calculate current path
	mut current_prefix := prefix

	// If this is not the root, add the character
	if node.character != 0 {
		current_prefix += node.character.ascii_str()
	}

	// If this marks the end of a key, add it to the result
	if node.is_end_of_string {
		println('Found key: ${current_prefix}')
		if current_prefix !in result {
			result << current_prefix
		}
	}

	// Visit all children
	if node.left_id != 0 {
		self.collect_all_keys(node.left_id, prefix, mut result)!
	}

	if node.middle_id != 0 {
		self.collect_all_keys(node.middle_id, current_prefix, mut result)!
	}

	if node.right_id != 0 {
		self.collect_all_keys(node.right_id, prefix, mut result)!
	}
}

// Gets all values for keys with a given prefix
pub fn (mut self TST) getall(prefix string) ![][]u8 {
	normalized_prefix := namefix(prefix)
	println('Getting all values with prefix: "${prefix}" (normalized: "${normalized_prefix}")')

	// Get all matching keys
	keys := self.list(normalized_prefix)!

	// Get values for each key
	mut values := [][]u8{}
	for key in keys {
		if value := self.get(key) {
			values << value
		}
	}

	println('Found ${values.len} values with prefix "${normalized_prefix}"')
	return values
}
