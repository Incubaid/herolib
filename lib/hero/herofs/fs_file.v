module herofs

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// FsFile represents a file in a filesystem
@[heap]
pub struct FsFile {
	db.Base
pub mut:
	fs_id       u32   // Associated filesystem
	directories []u32 // Directory IDs where this file exists
	blobs       []u32 // IDs of file content blobs
	size_bytes  u64
	mime_type   MimeType
	checksum    string // e.g., checksum of the file, needs to be calculated is blake 192
	accessed_at i64
	metadata    map[string]string // Custom metadata
}

pub struct DBFsFile {
pub mut:
	db      &db.DB     @[skip; str: skip]
	factory &FsFactory = unsafe { nil } @[skip; str: skip]
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
	directories_count := e.get_u16()!
	o.directories = []u32{cap: int(directories_count)}
	for _ in 0 .. directories_count {
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
	fs_id       u32 @[required]
	directories []u32
	blobs       []u32
	size_bytes  u64
	mime_type   MimeType // Changed from string to MimeType enum
	checksum    string
	accessed_at i64
	metadata    map[string]string
	tags        []string
	messages    []db.MessageArg
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
			_, blob_data := self.db.get_data[FsBlob](blob_id)!
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
		accessed_at: if args.accessed_at != 0 { args.accessed_at } else { ourtime.now().unix() }
		metadata:    args.metadata
	}

	// Set base fields
	o.description = args.description
	o.tags = self.db.tags_get(args.tags)!
	o.messages = self.db.messages_get(args.messages)!
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBFsFile) set(o_ FsFile) !FsFile {
	mut o := o_

	// Check that blobs exist
	for blob_id in o.blobs {
		blob_exists := self.db.exists[FsBlob](blob_id)!
		if !blob_exists {
			return error('Blob with ID ${blob_id} does not exist')
		}
	}

	// Check if this is a new file (id == 0) or an update
	is_new := o.id == 0

	// Get old directories if updating
	mut old_directories := []u32{}
	if !is_new {
		if old_file := self.get(o.id) {
			old_directories = old_file.directories.clone()
		}
	}

	o = self.db.set[FsFile](o)!

	// Maintain bidirectional relationship: update directory's files array
	if is_new {
		// New file: add to all specified directories
		for dir_id in o.directories {
			self.add_to_directory(o.id, dir_id)!
		}
	} else {
		// Updated file: handle directory changes
		// Remove from directories that are no longer associated
		for old_dir_id in old_directories {
			if old_dir_id !in o.directories {
				self.remove_from_directory(o.id, old_dir_id)!
			}
		}
		// Add to new directories
		for dir_id in o.directories {
			if dir_id !in old_directories {
				self.add_to_directory(o.id, dir_id)!
			}
		}
	}

	return o
}

// add_to_directory adds a file to a directory's files list
pub fn (mut self DBFsFile) add_to_directory(file_id u32, dir_id u32) ! {
	mut dir := self.factory.fs_dir.get(dir_id)!
	if file_id !in dir.files {
		dir.files << file_id
		dir = self.factory.fs_dir.set(dir)!
	}
}

// remove_from_directory removes a file from a directory's files list
pub fn (mut self DBFsFile) remove_from_directory(file_id u32, dir_id u32) ! {
	mut dir := self.factory.fs_dir.get(dir_id)!
	if file_id in dir.files {
		dir.files = dir.files.filter(it != file_id)
		dir = self.factory.fs_dir.set(dir)!
	}
}

pub fn (mut self DBFsFile) delete(id u32) ! {
	// Remove the file from all directories that contain it
	directories := self.list_directories_for_file(id)!
	for dir_id in directories {
		mut dir := self.factory.fs_dir.get(dir_id)!
		// Remove the file ID from the directory's files array
		dir.files = dir.files.filter(it != id)
		dir = self.factory.fs_dir.set(dir)!
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

// Update file accessed timestamp
pub fn (mut self DBFsFile) update_accessed(id u32) ! {
	mut file := self.get(id)!
	file.updated_at = ourtime.now().unix()
	self.set(file)!
}

// Update file metadata
pub fn (mut self DBFsFile) update_metadata(id u32, key string, value string) ! {
	mut file := self.get(id)!
	file.metadata[key] = value
	file.updated_at = ourtime.now().unix()
	self.set(file)!
}

// Rename file (affects all directories)
pub fn (mut self DBFsFile) rename(id u32, new_name string) ! {
	mut file := self.get(id)!
	file.name = new_name
	file.updated_at = ourtime.now().unix()
	self.set(file)!
}

// Move file to different directories
pub fn (mut self DBFsFile) move(id u32, new_dir_ids []u32) ! {
	// Verify all target directories exist
	for dir_id in new_dir_ids {
		if !self.db.exists[FsDir](dir_id)! {
			return error('Directory with ID ${dir_id} does not exist')
		}
	}

	// Remove file from all current directories
	for dir_id in self.list_directories_for_file(id)! {
		mut dir := self.factory.fs_dir.get(dir_id)!
		dir.files = dir.files.filter(it != id)
		dir = self.factory.fs_dir.set(dir)!
	}

	// Add file to new directories
	for dir_id in new_dir_ids {
		self.add_to_directory(id, dir_id)!
	}
}

// Append a blob to the file
pub fn (mut self DBFsFile) append_blob(id u32, blob_id u32) ! {
	// Verify blob exists
	if !self.db.exists[FsBlob](blob_id)! {
		return error('Blob with ID ${blob_id} does not exist')
	}

	mut file := self.get(id)!
	file.blobs << blob_id

	// Update file size
	_, blob_data := self.db.get_data[FsBlob](blob_id)!
	mut e_decoder := encoder.decoder_new(blob_data)

	// Skip hash
	e_decoder.get_string()!

	// Skip data, get size directly
	e_decoder.get_list_u8()!
	blob_size := u64(e_decoder.get_int()!)
	file.size_bytes += blob_size

	file.updated_at = ourtime.now().unix()
	file = self.set(file)!
}

// List all files
pub fn (mut self DBFsFile) list() ![]FsFile {
	ids := self.db.list[FsFile]()!
	mut files := []FsFile{}
	for id in ids {
		// Skip files that no longer exist (might have been deleted)
		if file := self.get(id) {
			files << file
		}
	}
	return files
}

// Get file by path (directory and name)
pub fn (mut self DBFsFile) get_by_path(dir_id u32, name string) !FsFile {
	dir := self.factory.fs_dir.get(dir_id)!
	for file_id in dir.files {
		file := self.get(file_id)!
		if file.name == name {
			return file
		}
	}
	return error('File "${name}" not found in directory ${dir_id}')
}

// List files in a directory
pub fn (mut self DBFsFile) list_by_directory(dir_id u32) ![]FsFile {
	dir := self.factory.fs_dir.get(dir_id)!
	mut files := []FsFile{}
	for file_id in dir.files {
		files << self.get(file_id)!
	}
	return files
}

// List files in a filesystem
pub fn (mut self DBFsFile) list_by_filesystem(fs_id u32) ![]FsFile {
	all_files := self.list()!
	return all_files.filter(it.fs_id == fs_id)
}

// List files by MIME type
pub fn (mut self DBFsFile) list_by_mime_type(mime_type MimeType) ![]FsFile {
	all_files := self.list()!
	return all_files.filter(it.mime_type == mime_type)
}

// Helper method to find which directories contain a file
pub fn (mut self DBFsFile) list_directories_for_file(file_id u32) ![]u32 {
	mut containing_dirs := []u32{}
	all_dirs := self.factory.fs_dir.list()!
	for dir in all_dirs {
		if file_id in dir.files {
			containing_dirs << dir.id
		}
	}
	return containing_dirs
}
