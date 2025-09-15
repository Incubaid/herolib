module herofs

import time
import crypto.blake3
import json
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// FsFile represents a file in a filesystem
@[heap]
pub struct FsFile {
	db.Base
pub mut:
	name        string
	fs_id       u32   // Associated filesystem
	directories []u32 // Directory IDs where this file exists, means file can be part of multiple directories (like hard links in Linux)
	blobs       []u32 // IDs of file content blobs
	size_bytes  u64
	mime_type   MimeType // MIME type as enum (MOVED FROM FsBlob)
	checksum    string // e.g., SHA256 checksum of the file
	accessed_at i64
	metadata    map[string]string // Custom metadata
}

pub struct DBFsFile {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self FsFile) type_name() string {
	return 'fs_file'
}

pub fn (self FsFile) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.fs_id)
	// Handle directories
	e.add_u16(u16(self.directories.len))
	for dir_id in self.directories {
		e.add_u32(dir_id)
	}

	// Handle blobs
	e.add_u16(u16(self.blobs.len))
	for blob_id in self.blobs {
		e.add_u32(blob_id)
	}

	e.add_u64(self.size_bytes)
	e.add_u8(u8(self.mime_type)) // ADD: Serialize mime_type as u8
	e.add_string(self.checksum)
	e.add_i64(self.accessed_at)

	// Handle metadata map
	e.add_u16(u16(self.metadata.len))
	for key, value in self.metadata {
		e.add_string(key)
		e.add_string(value)
	}
}

fn (mut self DBFsFile) load(mut o FsFile, mut e encoder.Decoder) ! {
	o.fs_id = e.get_u32()!

	// Load directories
	dirs_count := e.get_u16()!
	o.directories = []u32{cap: int(dirs_count)}
	for _ in 0 .. dirs_count {
		o.directories << e.get_u32()!
	}

	// Load blobs
	blobs_count := e.get_u16()!
	o.blobs = []u32{cap: int(blobs_count)}
	for _ in 0 .. blobs_count {
		o.blobs << e.get_u32()!
	}

	o.size_bytes = e.get_u64()!
	o.mime_type = unsafe { MimeType(e.get_u8()!) } // ADD: Deserialize mime_type
	o.checksum = e.get_string()!
	o.accessed_at = e.get_i64()!

	// Load metadata map
	metadata_count := e.get_u16()!
	o.metadata = map[string]string{}
	for _ in 0 .. metadata_count {
		key := e.get_string()!
		value := e.get_string()!
		o.metadata[key] = value
	}
}

@[params]
pub struct FsFileArg {
pub mut:
	name        string @[required]
	description string
	fs_id       u32   @[required]
	directories []u32 @[required]
	blobs       []u32
	size_bytes  u64
	mime_type   MimeType // Changed from string to MimeType enum
	checksum    string
	metadata    map[string]string
	tags        []string
	comments    []db.CommentArg
}

// get new file, not from the DB
pub fn (mut self DBFsFile) new(args FsFileArg) !FsFile {
	// Calculate size based on blobs if not provided
	mut size := args.size_bytes
	if size == 0 && args.blobs.len > 0 {
		// We'll need to sum the sizes of all blobs
		for blob_id in args.blobs {
			blob_exists := self.db.exists[FsBlob](blob_id)!
			if !blob_exists {
				return error('Blob with ID ${blob_id} does not exist')
			}

			// Get blob data
			mut blob_obj, blob_data := self.db.get_data[FsBlob](blob_id)!
			mut e_decoder := encoder.decoder_new(blob_data)

			// Skip hash
			e_decoder.get_string()!

			// Skip data, get size directly
			e_decoder.get_list_u8()!
			size += u64(e_decoder.get_int()!)
		}
	}

	mut o := FsFile{
		name:        args.name
		fs_id:       args.fs_id
		directories: args.directories
		blobs:       args.blobs
		size_bytes:  size
		mime_type:   args.mime_type // ADD: Set mime_type
		checksum:    args.checksum
		accessed_at: ourtime.now().unix()
		metadata:    args.metadata
	}

	// Set base fields
	o.description = args.description
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBFsFile) set(o FsFile) !u32 {
	// Check that directories exist
	for dir_id in o.directories {
		dir_exists := self.db.exists[FsDir](dir_id)!
		if !dir_exists {
			return error('Directory with ID ${dir_id} does not exist')
		}
	}

	// Check that blobs exist
	for blob_id in o.blobs {
		blob_exists := self.db.exists[FsBlob](blob_id)!
		if !blob_exists {
			return error('Blob with ID ${blob_id} does not exist')
		}
	}

	id := self.db.set[FsFile](o)!

	return id
}

pub fn (mut self DBFsFile) delete(id u32) ! {
	// Get the file info before deleting
	file := self.get(id)!
	// Delete the file itself
	self.db.delete[FsFile](id)!
}

pub fn (mut self DBFsFile) exist(id u32) !bool {
	return self.db.exists[FsFile](id)!
}

pub fn (mut self DBFsFile) get(id u32) !FsFile {
	mut o, data := self.db.get_data[FsFile](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

// Update file accessed timestamp
pub fn (mut self DBFsFile) update_accessed(id u32) !u32 {
	mut file := self.get(id)!
	file.accessed_at = ourtime.now().unix()
	return self.set(file)!
}

// Update file metadata
pub fn (mut self DBFsFile) update_metadata(id u32, key string, value string) !u32 {
	mut file := self.get(id)!
	file.metadata[key] = value
	file.updated_at = ourtime.now().unix()
	return self.set(file)!
}
