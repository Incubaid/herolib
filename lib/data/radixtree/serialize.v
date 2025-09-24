module radixtree

import freeflowuniverse.herolib.data.encoder

const version = u8(2) // Updated binary format version
const max_inline_value_size = 1024 // Values larger than this are stored out-of-line
const max_inline_children = 64 // Children lists larger than this are paged

// Serializes a node to bytes for storage
fn serialize_node(node Node) []u8 {
	mut e := encoder.new()

	// Add version byte
	e.add_u8(version)

	// Add flags byte (bit 0: is_leaf, bit 1: has_out_of_line_value, bit 2: has_paged_children)
	mut flags := u8(0)
	if node.is_leaf {
		flags |= 0x01
	}

	// Check if value should be stored out-of-line
	has_large_value := node.value.len > max_inline_value_size
	if has_large_value {
		flags |= 0x02
	}

	// Check if children should be paged
	has_many_children := node.children.len > max_inline_children
	if has_many_children {
		flags |= 0x04
	}

	e.add_u8(flags)

	// Note: key_segment is redundant and not stored (saves space)
	// It's only used for debugging and can be computed from traversal path

	// Add value (inline or reference)
	if has_large_value {
		// TODO: Store value out-of-line and store reference ID
		// For now, store inline but with u32 length to support larger values
		e.add_u32(u32(node.value.len))
		e.data << node.value
	} else {
		e.add_u16(u16(node.value.len))
		e.data << node.value
	}

	// Add children (inline or paged)
	if has_many_children {
		// TODO: Implement child paging for large fan-out
		// For now, store inline but warn about potential size issues
		e.add_u16(u16(node.children.len))
		for child in node.children {
			e.add_string(child.key_part)
			e.add_u32(child.node_id)
		}
	} else {
		e.add_u16(u16(node.children.len))
		for child in node.children {
			e.add_string(child.key_part)
			e.add_u32(child.node_id)
		}
	}

	return e.data
}

// Deserializes bytes to a node
fn deserialize_node(data []u8) !Node {
	mut d := encoder.decoder_new(data)

	// Read and verify version
	version_byte := d.get_u8()!
	if version_byte == 1 {
		// Handle old format for backward compatibility
		return deserialize_node_v1(data)
	} else if version_byte != version {
		return error('Invalid version byte: expected ${version}, got ${version_byte}')
	}

	// Read flags
	flags := d.get_u8()!
	is_leaf := (flags & 0x01) != 0
	has_out_of_line_value := (flags & 0x02) != 0
	has_paged_children := (flags & 0x04) != 0

	// Read value
	mut value := []u8{}
	if has_out_of_line_value {
		// TODO: Read value reference and fetch from separate storage
		value_len := d.get_u32()!
		value = []u8{len: int(value_len)}
		for i in 0 .. int(value_len) {
			value[i] = d.get_u8()!
		}
	} else {
		value_len := d.get_u16()!
		value = []u8{len: int(value_len)}
		for i in 0 .. int(value_len) {
			value[i] = d.get_u8()!
		}
	}

	// Read children
	mut children := []NodeRef{}
	if has_paged_children {
		// TODO: Read child page references and fetch children
		children_len := d.get_u16()!
		children = []NodeRef{cap: int(children_len)}
		for _ in 0 .. children_len {
			key_part := d.get_string()!
			node_id := d.get_u32()!
			children << NodeRef{
				key_part: key_part
				node_id:  node_id
			}
		}
	} else {
		children_len := d.get_u16()!
		children = []NodeRef{cap: int(children_len)}
		for _ in 0 .. children_len {
			key_part := d.get_string()!
			node_id := d.get_u32()!
			children << NodeRef{
				key_part: key_part
				node_id:  node_id
			}
		}
	}

	return Node{
		key_segment: '' // Not stored in new format
		value:       value
		children:    children
		is_leaf:     is_leaf
	}
}

// Backward compatibility for version 1 format
fn deserialize_node_v1(data []u8) !Node {
	mut d := encoder.decoder_new(data)

	// Skip version byte (already read)
	d.get_u8()!

	// Read key segment (ignored in new format)
	key_segment := d.get_string()!

	// Read value as []u8
	value_len := d.get_u16()!
	mut value := []u8{len: int(value_len)}
	for i in 0 .. int(value_len) {
		value[i] = d.get_u8()!
	}

	// Read children
	children_len := d.get_u16()!
	mut children := []NodeRef{cap: int(children_len)}
	for _ in 0 .. children_len {
		key_part := d.get_string()!
		node_id := d.get_u32()!
		children << NodeRef{
			key_part: key_part
			node_id:  node_id
		}
	}

	// Read leaf flag
	is_leaf := d.get_u8()! == 1

	return Node{
		key_segment: key_segment
		value:       value
		children:    children
		is_leaf:     is_leaf
	}
}
