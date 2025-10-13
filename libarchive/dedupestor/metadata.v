module dedupestor

// Metadata represents a stored value with its ID and references
pub struct Metadata {
pub:
	id u32
pub mut:
	references []Reference
}

// Reference represents a reference to stored data
pub struct Reference {
pub:
	owner u16
	id    u32
}

// to_bytes converts Metadata to bytes for storage
pub fn (m Metadata) to_bytes() []u8 {
	mut bytes := u32_to_bytes(m.id)
	for ref in m.references {
		bytes << ref.to_bytes()
	}
	return bytes
}

// bytes_to_metadata converts bytes back to Metadata
pub fn bytes_to_metadata(b []u8) Metadata {
	if b.len < 4 {
		return Metadata{
			id:         0
			references: []Reference{}
		}
	}

	id := bytes_to_u32(b[0..4])
	mut refs := []Reference{}

	// Parse references (each reference is 6 bytes)
	mut i := 4
	for i < b.len {
		if i + 6 <= b.len {
			refs << bytes_to_reference(b[i..i + 6])
		}
		i += 6
	}

	return Metadata{
		id:         id
		references: refs
	}
}

// add_reference adds a new reference if it doesn't already exist
pub fn (mut m Metadata) add_reference(ref Reference) !Metadata {
	// Check if reference already exists
	for existing in m.references {
		if existing.owner == ref.owner && existing.id == ref.id {
			return m
		}
	}

	m.references << ref
	return m
}

// remove_reference removes a reference if it exists
pub fn (mut m Metadata) remove_reference(ref Reference) !Metadata {
	mut new_refs := []Reference{}
	for existing in m.references {
		if existing.owner != ref.owner || existing.id != ref.id {
			new_refs << existing
		}
	}
	m.references = new_refs
	return m
}

// to_bytes converts Reference to bytes
pub fn (r Reference) to_bytes() []u8 {
	mut bytes := []u8{len: 6}
	bytes[0] = u8(r.owner)
	bytes[1] = u8(r.owner >> 8)
	bytes[2] = u8(r.id)
	bytes[3] = u8(r.id >> 8)
	bytes[4] = u8(r.id >> 16)
	bytes[5] = u8(r.id >> 24)
	return bytes
}

// bytes_to_reference converts bytes to Reference
pub fn bytes_to_reference(b []u8) Reference {
	owner := u16(b[0]) | (u16(b[1]) << 8)
	id := u32(b[2]) | (u32(b[3]) << 8) | (u32(b[4]) << 16) | (u32(b[5]) << 24)
	return Reference{
		owner: owner
		id:    id
	}
}

// Helper function to convert u32 to []u8
fn u32_to_bytes(n u32) []u8 {
	return [u8(n), u8(n >> 8), u8(n >> 16), u8(n >> 24)]
}

// Helper function to convert []u8 to u32
fn bytes_to_u32(b []u8) u32 {
	return u32(b[0]) | (u32(b[1]) << 8) | (u32(b[2]) << 16) | (u32(b[3]) << 24)
}
