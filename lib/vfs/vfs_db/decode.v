module vfs_db

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.vfs

// decode_directory decodes a binary format back to Directory
pub fn decode_directory(data []u8) !Directory {
	mut d := encoder.decoder_new(data)
	version := d.get_u8()!
	if version != 1 {
		return error('Unsupported version ${version}')
	}

	type_byte := d.get_u8()!
	if type_byte != u8(vfs.FileType.directory) {
		return error('Invalid type byte for directory')
	}

	// Decode metadata
	metadata := decode_metadata(mut d)!

	// Decode parent_id
	parent_id := d.get_u32()!

	// Decode children IDs
	children_count := int(d.get_u16()!)
	mut children := []u32{cap: children_count}

	for _ in 0 .. children_count {
		children << d.get_u32()!
	}

	return Directory{
		metadata:  metadata
		parent_id: parent_id
		children:  children
	}
}

// decode_file decodes a binary format back to File (without the actual file data)
// returns file without data and the sequence of keys of chunks of data in data db
pub fn decode_file_metadata(data []u8) !File {
	mut d := encoder.decoder_new(data)
	version := d.get_u8()!
	if version != 1 {
		return error('Unsupported version ${version}')
	}

	type_byte := d.get_u8()!
	if type_byte != u8(vfs.FileType.file) {
		return error('Invalid type byte for file')
	}

	// Decode metadata
	metadata := decode_metadata(mut d)!

	// Decode parent_id
	parent_id := d.get_u32()!

	mut chunk_ids := []u32{}
	if metadata.size == 0 {
		blocksize := d.get_u16() or { return error('Failed to get block size ${err}') }
		if blocksize != 0 {
			return error('File data is empty, expected zero block size')
		}
		// means there was no data_db ids stored with file, so is empty file
	} else {
		// Decode data_db block ID's
		// if data isn't empty, we expect a blocksize byte
		// blocksize is max 2 bytes, so max 4gb entry size
		blocksize := d.get_u16()!
		for i in 0 .. blocksize {
			chunk_ids << d.get_u32() or { return error('Failed to get block id ${err}') }
		}
	}

	return File{
		metadata:  metadata
		parent_id: parent_id
		chunk_ids: chunk_ids
	}
}

// decode_symlink decodes a binary format back to Symlink
pub fn decode_symlink(data []u8) !Symlink {
	mut d := encoder.decoder_new(data)
	version := d.get_u8()!
	if version != 1 {
		return error('Unsupported version ${version}')
	}

	type_byte := d.get_u8()!
	if type_byte != u8(vfs.FileType.symlink) {
		return error('Invalid type byte for symlink')
	}

	// Decode metadata
	metadata := decode_metadata(mut d)!

	// Decode parent_id
	parent_id := d.get_u32()!

	// Decode target path
	target := d.get_string()!

	return Symlink{
		metadata:  metadata
		parent_id: parent_id
		target:    target
	}
}

// decode_metadata decodes the common metadata structure
fn decode_metadata(mut d encoder.Decoder) !vfs.Metadata {
	id := d.get_u32()!
	name := d.get_string()!
	file_type_byte := d.get_u8()!
	size := d.get_u64()!
	created_at := d.get_i64()!
	modified_at := d.get_i64()!
	accessed_at := d.get_i64()!
	mode := d.get_u32()!
	owner := d.get_string()!
	group := d.get_string()!

	return vfs.Metadata{
		id:          id
		name:        name
		file_type:   unsafe { vfs.FileType(file_type_byte) }
		size:        size
		created_at:  created_at
		modified_at: modified_at
		accessed_at: accessed_at
		mode:        mode
		owner:       owner
		group:       group
	}
}

// decode_entry_type decodes the common metadata structure
fn decode_entry_type(data []u8) !vfs.FileType {
	if data.len < 2 {
		return error('Corrupt metadata bytes')
	}
	return unsafe { vfs.FileType(data[1]) }
}
