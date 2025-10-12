module tst

import incubaid.herolib.data.encoder

const version = u8(1) // Current binary format version

// Serializes a node to bytes for storage
fn serialize_node(node Node) []u8 {
	mut e := encoder.new()

	// Add version byte
	e.add_u8(version)

	// Add character
	e.add_u8(node.character)

	// Add is_end_of_string flag
	e.add_u8(if node.is_end_of_string { u8(1) } else { u8(0) })

	// Add value if this is the end of a string
	if node.is_end_of_string {
		e.add_bytes(node.value)
	} else {
		e.add_u32(0) // Empty value length
	}

	// Add child IDs
	e.add_u32(node.left_id)
	e.add_u32(node.middle_id)
	e.add_u32(node.right_id)

	return e.data
}

// Deserializes bytes to a node
fn deserialize_node(data []u8) !Node {
	mut d := encoder.decoder_new(data)

	// Read and verify version
	version_byte := d.get_u8()!
	if version_byte != version {
		return error('Invalid version byte: expected ${version}, got ${version_byte}')
	}

	// Read character
	character := d.get_u8()!

	// Read is_end_of_string flag
	is_end_of_string := d.get_u8()! == 1

	// Read value if this is the end of a string
	mut value := []u8{}
	if is_end_of_string {
		value = d.get_bytes()!
	} else {
		_ = d.get_u32()! // Skip empty value length
	}

	// Read child IDs
	left_id := d.get_u32()!
	middle_id := d.get_u32()!
	right_id := d.get_u32()!

	return Node{
		character:        character
		is_end_of_string: is_end_of_string
		value:            value
		left_id:          left_id
		middle_id:        middle_id
		right_id:         right_id
	}
}
