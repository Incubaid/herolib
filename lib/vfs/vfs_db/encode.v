module vfs_db

import incubaid.herolib.data.encoder
import incubaid.herolib.vfs

// encode_metadata encodes the common metadata structure
fn encode_metadata(mut e encoder.Encoder, m vfs.Metadata) {
	e.add_u32(m.id)
	e.add_string(m.name)
	e.add_u8(u8(m.file_type)) // FileType enum as u8
	e.add_u64(m.size)
	e.add_i64(m.created_at)
	e.add_i64(m.modified_at)
	e.add_i64(m.accessed_at)
	e.add_u32(m.mode)
	e.add_string(m.owner)
	e.add_string(m.group)
}

// encode encodes a Directory to binary format
pub fn (dir Directory) encode() []u8 {
	mut e := encoder.new()
	e.add_u8(1) // version byte
	e.add_u8(u8(vfs.FileType.directory)) // type byte

	// Encode metadata
	encode_metadata(mut e, dir.metadata)

	// Encode parent_id
	e.add_u32(dir.parent_id)

	// Encode children IDs
	e.add_u16(u16(dir.children.len))
	for child_id in dir.children {
		e.add_u32(child_id)
	}

	return e.data
}

// File encoding/decoding
// encode encodes a File metadata to binary format (without the actual file data)
pub fn (f File) encode() []u8 {
	mut e := encoder.new()
	e.add_u8(1) // version byte
	e.add_u8(u8(vfs.FileType.file)) // type byte

	// Encode metadata
	encode_metadata(mut e, f.metadata)

	// Encode parent_id
	e.add_u32(f.parent_id)

	// Encode blocksize and block ids
	// if file has no data, it also should have zero block size
	e.add_u16(u16(f.chunk_ids.len))
	for id in f.chunk_ids {
		e.add_u32(id)
	}
	return e.data
}

// encode encodes a Symlink to binary format
pub fn (sl Symlink) encode() []u8 {
	mut e := encoder.new()
	e.add_u8(1) // version byte
	e.add_u8(u8(vfs.FileType.symlink)) // type byte

	// Encode metadata
	encode_metadata(mut e, sl.metadata)

	// Encode parent_id
	e.add_u32(sl.parent_id)

	// Encode target path
	e.add_string(sl.target)

	return e.data
}
