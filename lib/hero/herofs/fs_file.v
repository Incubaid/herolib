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
	fs_id       u32     // Associated filesystem
	directories []u32   // Directory IDs where this file exists, means file can be part of multiple directories (like hard links in Linux)
	blobs       []u32   // IDs of file content blobs
	size_bytes  u64    
	mime_type   string  // e.g., "image/png"
	checksum    string  // e.g., SHA256 checksum of the file
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

pub fn (self FsFile) dump(mut e &encoder.Encoder) ! {
	e.add_string(self.name)
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
	e.add_string(self.mime_type)
	e.add_string(self.checksum)
	e.add_i64(self.accessed_at)
	
	// Handle metadata map
	e.add_u16(u16(self.metadata.len))
	for key, value in self.metadata {
		e.add_string(key)
		e.add_string(value)
	}
}

fn (mut self DBFsFile) load(mut o FsFile, mut e &encoder.Decoder) ! {
	o.name = e.get_string()!
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
	o.mime_type = e.get_string()!
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
	name          string @[required]
	description   string
	fs_id         u32 @[required]
	directories   []u32 @[required]
	blobs         []u32
	size_bytes    u64
	mime_type     string
	checksum      string
	metadata      map[string]string
	tags          []string
	comments      []db.CommentArg
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
		name: args.name,
		fs_id: args.fs_id,
		directories: args.directories,
		blobs: args.blobs,
		size_bytes: size,
		mime_type: args.mime_type,
		checksum: args.checksum,
		accessed_at: ourtime.now().unix(),
		metadata: args.metadata
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
	
	// Store file in each directory's file index
	for dir_id in o.directories {
		// Store by name in each directory
		path_key := '${dir_id}:${o.name}'
		self.db.redis.hset('fsfile:paths', path_key, id.str())!
		
		// Add to directory's file list using hset
		self.db.redis.hset('fsfile:dir:${dir_id}', id.str(), id.str())!
	}
	
	// Store in filesystem's file list using hset
	self.db.redis.hset('fsfile:fs:${o.fs_id}', id.str(), id.str())!
	
	// Store by mimetype using hset
	if o.mime_type != '' {
		self.db.redis.hset('fsfile:mime:${o.mime_type}', id.str(), id.str())!
	}
	
	return id
}

pub fn (mut self DBFsFile) delete(id u32) ! {
	// Get the file info before deleting
	file := self.get(id)!
	
	// Remove from each directory's file index
	for dir_id in file.directories {
		// Remove from path index
		path_key := '${dir_id}:${file.name}'
		self.db.redis.hdel('fsfile:paths', path_key)!
		
		// Remove from directory's file list using hdel
		self.db.redis.hdel('fsfile:dir:${dir_id}', id.str())!
	}
	
	// Remove from filesystem's file list using hdel
	self.db.redis.hdel('fsfile:fs:${file.fs_id}', id.str())!
	
	// Remove from mimetype index using hdel
	if file.mime_type != '' {
		self.db.redis.hdel('fsfile:mime:${file.mime_type}', id.str())!
	}
	
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

pub fn (mut self DBFsFile) list() ![]FsFile {
	return self.db.list[FsFile]()!.map(self.get(it)!)
}

// Get file by path in a specific directory
pub fn (mut self DBFsFile) get_by_path(dir_id u32, name string) !FsFile {
	path_key := '${dir_id}:${name}'
	id_str := self.db.redis.hget('fsfile:paths', path_key)!
	if id_str == '' {
		return error('File "${name}" not found in directory ${dir_id}')
	}
	return self.get(id_str.u32())!
}

// List files in a directory
pub fn (mut self DBFsFile) list_by_directory(dir_id u32) ![]FsFile {
	file_ids := self.db.redis.hkeys('fsfile:dir:${dir_id}')!
	mut files := []FsFile{}
	for id_str in file_ids {
		files << self.get(id_str.u32())!
	}
	return files
}

// List files in a filesystem
pub fn (mut self DBFsFile) list_by_filesystem(fs_id u32) ![]FsFile {
	file_ids := self.db.redis.hkeys('fsfile:fs:${fs_id}')!
	mut files := []FsFile{}
	for id_str in file_ids {
		files << self.get(id_str.u32())!
	}
	return files
}

// List files by mime type
pub fn (mut self DBFsFile) list_by_mime_type(mime_type string) ![]FsFile {
	file_ids := self.db.redis.hkeys('fsfile:mime:${mime_type}')!
	mut files := []FsFile{}
	for id_str in file_ids {
		files << self.get(id_str.u32())!
	}
	return files
}

// Update file with a new blob (append)
pub fn (mut self DBFsFile) append_blob(id u32, blob_id u32) !u32 {
	// Check blob exists
	blob_exists := self.db.exists[FsBlob](blob_id)!
	if !blob_exists {
		return error('Blob with ID ${blob_id} does not exist')
	}
	
	// Get blob size
	mut blob_obj, blob_data := self.db.get_data[FsBlob](blob_id)!
	mut e_decoder := encoder.decoder_new(blob_data)
	
	// Skip hash
	e_decoder.get_string()!
	
	// Skip data, get size directly
	e_decoder.get_list_u8()!
	blob_size := e_decoder.get_int()!
	
	// Get file
	mut file := self.get(id)!
	
	// Add blob if not already in the list
	if blob_id !in file.blobs {
		file.blobs << blob_id
		file.size_bytes += u64(blob_size)
		file.updated_at = ourtime.now().unix()
	}
	
	// Save file
	return self.set(file)!
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

// Rename a file
pub fn (mut self DBFsFile) rename(id u32, new_name string) !u32 {
	mut file := self.get(id)!
	
	// Remove old path indexes
	for dir_id in file.directories {
		old_path_key := '${dir_id}:${file.name}'
		self.db.redis.hdel('fsfile:paths', old_path_key)!
	}
	
	// Update name
	file.name = new_name
	
	// Save with new name
	return self.set(file)!
}

// Move file to different directories
pub fn (mut self DBFsFile) move(id u32, new_directories []u32) !u32 {
	mut file := self.get(id)!
	
	// Check that all new directories exist
	for dir_id in new_directories {
		dir_exists := self.db.exists[FsDir](dir_id)!
		if !dir_exists {
			return error('Directory with ID ${dir_id} does not exist')
		}
	}
	
	// Remove from old directories
	for dir_id in file.directories {
		path_key := '${dir_id}:${file.name}'
		self.db.redis.hdel('fsfile:paths', path_key)!
		self.db.redis.hdel('fsfile:dir:${dir_id}', id.str())!
	}
	
	// Update directories
	file.directories = new_directories
	
	// Save with new directories
	return self.set(file)!
}