module radixtree

import freeflowuniverse.herolib.ui.console

// Gets a node from the database by its ID
pub fn (mut rt RadixTree) get_node_by_id(id u32) !Node {
	node_data := rt.db.get(id)!
	node := deserialize_node(node_data)!
	// console.print_debug('Debug: Retrieved node ${id} with ${node.children.len} children')
	return node
}

// Logs the current state of a node
pub fn (mut rt RadixTree) debug_node(id u32, msg string) ! {
	// node := rt.get_node_by_id(id)!
	// // console.print_debug('Debug: ${msg}')
	// // console.print_debug('  Node ID: ${id}')
	// // console.print_debug('  Key Segment: "${node.key_segment}"')
	// // console.print_debug('  Is Leaf: ${node.is_leaf}')
	// // console.print_debug('  Children: ${node.children.len}')
	// for child in node.children {
	// 	// console.print_debug('    - Child ID: ${child.node_id}, Key Part: "${child.key_part}"')
	// }
}

// Prints the current state of the database
pub fn (mut rt RadixTree) debug_db() ! {
	// console.print_debug('\nDatabase State:')
	// console.print_debug('===============')
	mut next_id := rt.db.get_next_id()!
	for id := u32(0); id < next_id; id++ {
		if data := rt.db.get(id) {
			if node := deserialize_node(data) {
				console.print_debug('ID ${id}:')
				console.print_debug('  Key Segment: "${node.key_segment}"')
				console.print_debug('  Is Leaf: ${node.is_leaf}')
				console.print_debug('  Children: ${node.children.len}')
				for child in node.children {
					console.print_debug('    - Child ID: ${child.node_id}, Key Part: "${child.key_part}"')
				}
			} else {
				console.print_debug('ID ${id}: Failed to deserialize node')
			}
		} else {
			console.print_debug('ID ${id}: No data')
		}
	}
}

// Prints the tree structure starting from a given node ID
pub fn (mut rt RadixTree) print_tree_from_node(node_id u32, indent string) ! {
	node := rt.get_node_by_id(node_id)!

	mut node_info := '${indent}Node(id: ${node_id})'
	node_info += '\n${indent}├── key_segment: "${node.key_segment}"'
	node_info += '\n${indent}├── is_leaf: ${node.is_leaf}'
	if node.is_leaf {
		node_info += '\n${indent}├── value: ${node.value.bytestr()}'
	}
	node_info += '\n${indent}└── children: ${node.children.len}'
	if node.children.len > 0 {
		node_info += ' ['
		for i, child in node.children {
			if i > 0 {
				node_info += ', '
			}
			node_info += '${child.node_id}:${child.key_part}'
		}
		node_info += ']'
	}
	console.print_debug(node_info)

	// Print children recursively with increased indentation
	for i, child in node.children {
		is_last := i == node.children.len - 1
		child_indent := if is_last {
			indent + '    '
		} else {
			indent + '│   '
		}
		rt.print_tree_from_node(child.node_id, child_indent)!
	}
}

// Prints the entire tree structure starting from root
pub fn (mut rt RadixTree) print_tree() ! {
	console.print_debug('\nRadix Tree Structure:')
	console.print_debug('===================')
	rt.print_tree_from_node(rt.root_id, '')!
}

// Gets detailed information about a specific node
pub fn (mut rt RadixTree) get_node_info(id u32) !string {
	node := rt.get_node_by_id(id)!

	mut info := 'Node Details:\n'
	info += '=============\n'
	info += 'ID: ${id}\n'
	info += 'Key Segment: "${node.key_segment}"\n'
	info += 'Is Leaf: ${node.is_leaf}\n'
	if node.is_leaf {
		info += 'Value: ${node.value}\n'
	}
	info += 'Number of Children: ${node.children.len}\n'
	if node.children.len > 0 {
		info += '\nChildren:\n'
		for child in node.children {
			info += '- ID: ${child.node_id}, Key Part: "${child.key_part}"\n'
		}
	}

	return info
}
