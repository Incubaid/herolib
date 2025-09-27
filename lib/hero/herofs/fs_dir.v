module herofs

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_ok, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import freeflowuniverse.herolib.ui.console
import json

// FsDir represents a directory in a filesystem
@[heap]
pub struct FsDir {
	db.Base
pub mut:
	fs_id       u32 // Associated filesystem
	parent_id   u32 // Parent directory ID (0 for root)
	directories []u32
	files       []u32
	symlinks    []u32
}

pub struct DBFsDir {
pub mut:
	db      &db.DB     @[skip; str: skip]
	factory &FSFactory = unsafe { nil } @[skip; str: skip]
}

pub fn (self FsDir) type_name() string {
	return 'fs_dir'
}

pub fn (self FsDir) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.fs_id)
	e.add_u32(self.parent_id)

	// Handle directories array
	e.add_u16(u16(self.directories.len))
	for dir_id in self.directories {
		e.add_u32(dir_id)
	}

	// Handle files array
	e.add_u16(u16(self.files.len))
	for file_id in self.files {
		e.add_u32(file_id)
	}

	// Handle symlinks array
	e.add_u16(u16(self.symlinks.len))
	for symlink_id in self.symlinks {
		e.add_u32(symlink_id)
	}
}

fn (mut self DBFsDir) load(mut o FsDir, mut e encoder.Decoder) ! {
	o.fs_id = e.get_u32()!
	o.parent_id = e.get_u32()!

	// Load directories array
	directories_count := e.get_u16()!
	o.directories = []u32{cap: int(directories_count)}
	for _ in 0 .. directories_count {
		o.directories << e.get_u32()!
	}

	// Load files array
	files_count := e.get_u16()!
	o.files = []u32{cap: int(files_count)}
	for _ in 0 .. files_count {
		o.files << e.get_u32()!
	}

	// Load symlinks array
	symlinks_count := e.get_u16()!
	o.symlinks = []u32{cap: int(symlinks_count)}
	for _ in 0 .. symlinks_count {
		o.symlinks << e.get_u32()!
	}
}

@[params]
pub struct FsDirArg {
pub mut:
	name        string @[required]
	description string
	fs_id       u32 @[required]
	parent_id   u32
	tags        []string
	messages    []db.MessageArg
	directories []u32
	files       []u32
	symlinks    []u32
}

// get new directory, not from the DB
pub fn (mut self DBFsDir) new(args FsDirArg) !FsDir {
	mut o := FsDir{
		name:        args.name
		description: args.description
		fs_id:       args.fs_id
		parent_id:   args.parent_id
		directories: args.directories
		files:       args.files
		symlinks:    args.symlinks
	}

	// Set base fields
	o.tags = self.db.tags_get(args.tags)!
	o.messages = self.db.messages_get(args.messages)!
	o.created_at = ourtime.now().unix()
	o.updated_at = o.created_at

	return o
}

pub fn (mut self DBFsDir) set(o FsDir) !FsDir {
	o_result := self.db.set[FsDir](o)!
	return o_result
}

pub fn (mut self DBFsDir) delete(id u32) ! {
	// Get the directory info before deleting
	dir := self.get(id)!

	// If has parent, remove from parent's directories list
	if dir.parent_id > 0 {
		mut parent_dir := self.factory.fs_dir.get(dir.parent_id) or {
			return error('Parent directory with ID ${dir.parent_id} does not exist')
		}
		parent_dir.directories = parent_dir.directories.filter(it != id)
		parent_dir = self.factory.fs_dir.set(parent_dir)!
	}
	// Delete the directory itself
	self.db.delete[FsDir](id)!
}

pub fn (mut self DBFsDir) exist(id u32) !bool {
	return self.db.exists[FsDir](id)!
}

pub fn (mut self DBFsDir) get(id u32) !FsDir {
	mut o, data := self.db.get_data[FsDir](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

// create_path creates a directory at the specified path, creating parent directories as needed
pub fn (mut self DBFsDir) create_path(fs_id u32, path string) !u32 {
	if path == '/' {
		// Return root directory ID
		fs := self.factory.fs.get(fs_id)!
		return fs.root_dir_id
	}

	// Split path into components
	components := path.trim('/').split('/')
	mut current_parent_id := u32(0)

	// Get root directory
	fs := self.factory.fs.get(fs_id)!
	current_parent_id = fs.root_dir_id

	// Create each directory in the path
	for component in components {
		if component == '' {
			continue
		}

		// Check if directory already exists
		mut found_id := u32(0)
		if current_parent_id > 0 {
			parent_dir := self.get(current_parent_id)!
			for child_id in parent_dir.directories {
				child_dir := self.get(child_id)!
				if child_dir.name == component {
					found_id = child_id
					break
				}
			}
		}

		if found_id > 0 {
			current_parent_id = found_id
		} else {
			// Create new directory
			mut new_dir := self.new(
				name:      component
				fs_id:     fs_id
				parent_id: current_parent_id
			)!
			new_dir = self.set(new_dir)!

			// Add to parent's directories list
			if current_parent_id > 0 {
				mut parent_dir := self.get(current_parent_id)!
				parent_dir.directories << new_dir.id
				parent_dir = self.set(parent_dir)!
			}

			current_parent_id = new_dir.id
		}
	}

	return current_parent_id
}

// List all directories
pub fn (mut self DBFsDir) list() ![]FsDir {
	ids := self.db.list[FsDir]()!
	mut dirs := []FsDir{}
	for id in ids {
		dirs << self.get(id)!
	}
	return dirs
}

// List directories in a filesystem
pub fn (mut self DBFsDir) list_by_filesystem(fs_id u32) ![]FsDir {
	all_dirs := self.list()!
	return all_dirs.filter(it.fs_id == fs_id)
}

// List child directories
pub fn (mut self DBFsDir) list_children(dir_id u32) ![]FsDir {
	parent_dir := self.get(dir_id)!
	mut children := []FsDir{}
	for child_id in parent_dir.directories {
		children << self.get(child_id)!
	}
	return children
}

// Check if directory has children
pub fn (mut self DBFsDir) has_children(dir_id u32) !bool {
	dir := self.get(dir_id)!
	return dir.directories.len > 0 || dir.files.len > 0 || dir.symlinks.len > 0
}

// Rename directory
pub fn (mut self DBFsDir) rename(id u32, new_name string) ! {
	mut dir := self.get(id)!
	dir.name = new_name
	dir.updated_at = ourtime.now().unix()
	dir = self.set(dir)!
}

// Move directory to a new parent
pub fn (mut self DBFsDir) move(id u32, new_parent_id u32) ! {
	// Verify new parent exists
	if new_parent_id > 0 && !self.exist(new_parent_id)! {
		return error('New parent directory with ID ${new_parent_id} does not exist')
	}

	mut dir := self.get(id)!
	old_parent_id := dir.parent_id

	// Remove from old parent's directories list
	if old_parent_id > 0 {
		mut old_parent := self.get(old_parent_id)!
		old_parent.directories = old_parent.directories.filter(it != id)
		old_parent = self.set(old_parent)!
	}

	// Add to new parent's directories list
	if new_parent_id > 0 {
		mut new_parent := self.get(new_parent_id)!
		if id !in new_parent.directories {
			new_parent.directories << id
		}
		new_parent = self.set(new_parent)!
	}

	// Update directory's parent_id
	dir.parent_id = new_parent_id
	dir.updated_at = ourtime.now().unix()
	dir = self.set(dir)!
}

pub fn (self FsDir) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a directory. Returns the ID of the directory.'
		}
		'get' {
			return 'Retrieve a directory by ID. Returns the directory object.'
		}
		'delete' {
			return 'Delete a directory by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a directory exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all directories. Returns an array of directory objects.'
		}
		'create_path' {
			return 'Create a directory path. Returns the ID of the created directory.'
		}
		else {
			return 'This is generic method for the directory object.'
		}
	}
}

pub fn (self FsDir) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"dir": {"name": "documents", "fs_id": 1, "parent_id": 2}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "documents", "fs_id": 1, "parent_id": 2, "directories": [], "files": [], "symlinks": []}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "documents", "fs_id": 1, "parent_id": 2, "directories": [], "files": [], "symlinks": []}]'
		}
		'create_path' {
			return '{"fs_id": 1, "path": "/projects/web/frontend"}', '5'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn fs_dir_handle(mut f FSFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.fs_dir.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut o := db.decode_generic[FsDir](params)!
			o = f.fs_dir.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			f.fs_dir.delete(id)!
			return new_response_ok(rpcid)
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.fs_dir.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			res := f.fs_dir.list()!
			return new_response(rpcid, json.encode(res))
		}
		else {
			console.print_stderr('Method not found on fs_dir: ${method}')
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on fs_dir'
			)
		}
	}
}
