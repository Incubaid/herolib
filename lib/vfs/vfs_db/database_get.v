module vfs_db

import arrays
import incubaid.herolib.vfs
import incubaid.herolib.data.ourdb
import incubaid.herolib.data.encoder
import time
import log

// DatabaseVFS represents the virtual filesystem
@[heap]
pub struct DatabaseVFS {
pub mut:
	root_id          u32 // ID of root directory
	block_size       u32 // Size of data blocks in bytes
	db_data          &Database @[str: skip] // Database instance for file data storage
	db_metadata      &Database @[str: skip] // Database instance for metadata storage
	last_inserted_id u32
	id_table         map[u32]u32
}

pub interface Database {
mut:
	get(id u32) ![]u8
	set(ourdb.OurDBSetArgs) !u32
	delete(id u32) !
}

// Get the next ID, it should be some kind of auto-incrementing ID
pub fn (mut fs DatabaseVFS) get_next_id() u32 {
	fs.last_inserted_id = fs.last_inserted_id + 1
	return fs.last_inserted_id
}

// load_entry loads an entry from the database by ID and sets up parent references
// loads without data
fn (mut fs DatabaseVFS) load_entry(vfs_id u32) !FSEntry {
	if db_id := fs.id_table[vfs_id] {
		if metadata := fs.db_metadata.get(db_id) {
			match decode_entry_type(metadata)! {
				.directory {
					mut dir := decode_directory(metadata) or {
						return error('Failed to decode directory: ${err}')
					}
					return dir
				}
				.file {
					return decode_file_metadata(metadata) or {
						return error('Failed to decode file: ${err}')
					}
				}
				.symlink {
					mut symlink := decode_symlink(metadata) or {
						return error('Failed to decode symlink: ${err}')
					}
					return symlink
				}
			}
		} else {
			return error('Entry ${vfs_id} not found ${err}')
		}
	} else {
		return error('Entry ${vfs_id} not found')
	}
}

// fn (mut fs DatabaseVFS) file_read(file File) ![]u8 {
// 	metadata := fs.db_metadata.get(fs.get_database_id(file.metadata.id)!) or {
// 		return error('Failed to get file metadata ${err}')
// 	}
// 	_, chunk_ids := decode_file_metadata(metadata) or { return error('Failed to decode file: ${err}') }
// 	mut file_data := []u8{}
// 	// log.debug('[DatabaseVFS] Got database chunk ids ${chunk_ids}')
// 	for id in chunk_ids {
// 		// there were chunk ids stored with file so file has data
// 		if chunk_bytes := fs.db_data.get(id) {
// 			file_data << chunk_bytes
// 		} else {
// 			return error('Failed to fetch file data: ${err}')
// 		}
// 	}
// 	return file_data
// }

fn (mut self DatabaseVFS) get_entry(path string) !FSEntry {
	if path == '/' || path == '' || path == '.' {
		return FSEntry(self.root_get_as_dir()!)
	}
	parts := path.trim_string_left('/').split('/')
	mut parent_dir := *self.root_get_as_dir()!
	for i, part in parts {
		entry := self.directory_get_entry(parent_dir, part) or {
			return error('Failed to get entry ${err}')
		}
		if i == parts.len - 1 {
			// last part, means entry is found
			return entry
		}
		if entry is Directory {
			parent_dir = entry
		} else {
			return error('Failed to get entry, expected dir')
		}
	}
	// mut current := *self.root_get_as_dir()!
	// return self.directory_get_entry(mut current, path) or {
	return error('Path not found: ${path}')
	// }
}

// internal function to get an entry of some name from a directory
fn (mut self DatabaseVFS) directory_get_entry(dir Directory, name string) ?FSEntry {
	// mut children := self.directory_children(mut dir, false) or {
	// 	panic('this should never happen')
	// }
	for child_id in dir.children {
		if entry := self.load_entry(child_id) {
			if entry.metadata.name == name {
				return entry
			}
		} else {
			panic('Filesystem is corrupted, this should never happen ${err}')
		}
	}
	return none
}

fn (mut self DatabaseVFS) get_directory(path string) !&Directory {
	mut entry := self.get_entry(path)!
	if mut entry is Directory {
		return &entry
	}
	return error('Not a directory: ${path}')
}

pub fn (mut self DatabaseVFS) get_path(entry_ &vfs.FSEntry) !string {
	// entry := self.load_entry(entry_.metadata.)
	// entry.parent_id == 0 {
	// 	return '/${entry.metadata.name}'
	// } else {
	// 	parent := self.load_entry(entry.parent_id)!
	// 	return '${self.get_path(parent)!}/${entry.metadata.name}'
	// }
	return ''
}

// Implementation of VFSImplementation interface
pub fn (mut fs DatabaseVFS) root_get_as_dir() !&Directory {
	// Try to load root directory from DB if it exists

	if db_id := fs.id_table[fs.root_id] {
		if data := fs.db_metadata.get(db_id) {
			mut loaded_root := decode_directory(data) or {
				panic('Failed to decode root directory: ${err}')
			}
			return &loaded_root
		}
	}

	// Create and save new root directory
	mut myroot := Directory{
		metadata:  vfs.Metadata{
			id:          fs.get_next_id()
			file_type:   .directory
			name:        ''
			created_at:  time.utc().unix()
			modified_at: time.utc().unix()
			accessed_at: time.utc().unix()
			mode:        0o755  // default directory permissions
			owner:       'user' // TODO: get from system
			group:       'user' // TODO: get from system
		}
		parent_id: 0
	}
	fs.save_entry(myroot) or { return error('failed to set root ${err}') }
	fs.root_id = myroot.metadata.id
	return &myroot
}
