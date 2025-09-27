module herofs

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_ok, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import freeflowuniverse.herolib.ui.console
import json

// FsFile represents a file in a filesystem
@[heap]
pub struct FsFile {
	db.Base
pub mut:
	fs_id      u32   // Associated filesystem
	blobs      []u32 // IDs of file content blobs
	size_bytes u64
	mime_type  MimeType
	checksum   string            // e.g., checksum of the file, needs to be calculated is blake 192
	metadata   map[string]string // Custom metadata
}

pub struct DBFsFile {
pub mut:
	db      &db.DB     @[skip; str: skip]
	factory &ModelsFactory = unsafe { nil } @[skip; str: skip]
}

pub fn (self FsFile) type_name() string {
	return 'fs_file'
}

pub fn (self FsFile) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.fs_id)
	// Handle blobs
	e.add_u16(u16(self.blobs.len))
	for blob_id in self.blobs {
		e.add_u32(blob_id)
	}

	e.add_u64(self.size_bytes)
	e.add_u8(u8(self.mime_type)) // ADD: Serialize mime_type as u8
	e.add_string(self.checksum)

	// Handle metadata map
	e.add_u16(u16(self.metadata.len))
	for key, value in self.metadata {
		e.add_string(key)
		e.add_string(value)
	}
}

fn (mut self DBFsFile) load(mut o FsFile, mut e encoder.Decoder) ! {
	o.fs_id = e.get_u32()!

	// Load blobs
	blobs_count := e.get_u16()!
	o.blobs = []u32{cap: int(blobs_count)}
	for _ in 0 .. blobs_count {
		o.blobs << e.get_u32()!
	}

	o.size_bytes = e.get_u64()!
	o.mime_type = unsafe { MimeType(e.get_u8()!) } // ADD: Deserialize mime_type
	o.checksum = e.get_string()!

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
		name:       args.name
		fs_id:      args.fs_id
		blobs:      args.blobs
		size_bytes: size
		mime_type:  args.mime_type // ADD: Set mime_type
		checksum:   args.checksum
		metadata:   args.metadata
	}

	// Set base fields
	o.description = args.description
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
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
	o = self.db.set[FsFile](o)!

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

pub fn (self FsFile) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a file. Returns the ID of the file.'
		}
		'get' {
			return 'Retrieve a file by ID. Returns the file object.'
		}
		'delete' {
			return 'Delete a file by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a file exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all files. Returns an array of file objects.'
		}
		'rename' {
			return 'Rename a file. Returns true if successful.'
		}
		else {
			return 'This is generic method for the file object.'
		}
	}
}

pub fn (self FsFile) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"file": {"name": "document.txt", "fs_id": 1, "blobs": [1], "mime_type": "txt"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "document.txt", "fs_id": 1, "blobs": [1], "size_bytes": 1024, "mime_type": "txt"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "document.txt", "fs_id": 1, "blobs": [1], "size_bytes": 1024, "mime_type": "txt"}]'
		}
		'rename' {
			return '{"id": 1, "new_name": "renamed_document.txt"}', 'true'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn fs_file_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.fs_file.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut o := db.decode_generic[FsFile](params)!
			o = f.fs_file.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			f.fs_file.delete(id)!
			return new_response_ok(rpcid)
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.fs_file.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			res := f.fs_file.list()!
			return new_response(rpcid, json.encode(res))
		}
		else {
			console.print_stderr('Method not found on fs_file: ${method}')
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on fs_file'
			)
		}
	}
}