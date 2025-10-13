module vfs_db

import incubaid.herolib.vfs { Metadata }
import time
import log

// mkdir creates a new directory with default permissions
pub fn (mut fs DatabaseVFS) directory_mkdir(mut dir Directory, name_ string) !&Directory {
	name := name_.trim('/')
	// Check if directory already exists
	for child_id in dir.children {
		if entry := fs.load_entry(child_id) {
			if entry.metadata.name == name {
				return error('Directory ${name} already exists')
			}
		}
	}

	new_dir := fs.new_directory(
		name:      name
		parent_id: dir.metadata.id
	)!
	dir.children << new_dir.metadata.id
	fs.save_entry(dir)!
	return new_dir
}

pub struct NewDirectory {
pub:
	name      string @[required] // name of file or directory
	mode      u32    = 0o755 // file permissions
	owner     string = 'user'
	group     string = 'user'
	parent_id u32
	children  []u32
}

// mkdir creates a new directory with default permissions
pub fn (mut fs DatabaseVFS) new_directory(dir NewDirectory) !&Directory {
	d := Directory{
		parent_id: dir.parent_id
		metadata:  vfs.new_metadata(
			id:        fs.get_next_id()
			name:      dir.name
			mode:      dir.mode
			owner:     dir.owner
			group:     dir.group
			size:      u64(0)
			file_type: .directory
		)
		children:  dir.children
	}
	// Save new directory to DB
	fs.save_entry(d)!
	return &d
}

// copy_directory creates a new directory with the same metadata as the source
pub fn (mut fs DatabaseVFS) copy_directory(dir Directory) !&Directory {
	// Ensure we get a new ID that's different from the original
	mut new_id := fs.get_next_id()

	// Make sure the new ID is different from the original
	if new_id == dir.metadata.id {
		new_id = fs.get_next_id() // Get another ID if they happen to be the same
	}

	new_dir := Directory{
		metadata:  Metadata{
			...dir.metadata
			id:          new_id
			created_at:  time.now().unix()
			modified_at: time.now().unix()
			accessed_at: time.now().unix()
		}
		children:  []u32{}
		parent_id: dir.parent_id
	}
	fs.save_entry(new_dir)!
	return &new_dir
}

// touch creates a new empty file with default permissions
pub fn (mut fs DatabaseVFS) directory_touch(mut dir Directory, name_ string) !&File {
	name := name_.trim('/')

	// Check if file already exists
	for child_id in dir.children {
		if entry := fs.load_entry(child_id) {
			if entry.metadata.name == name {
				return error('File ${name} already exists')
			}
		}
	}

	// Create new file with correct parent_id
	mut file_id := fs.save_file(File{
		parent_id: dir.metadata.id
		metadata:  Metadata{
			id:          fs.get_next_id()
			name:        name
			file_type:   .file
			created_at:  time.now().unix()
			modified_at: time.now().unix()
			accessed_at: time.now().unix()
			mode:        0o644
			owner:       'user'
			group:       'user'
		}
	}, [])!

	// Update children list
	dir.children << file_id
	fs.save_entry(dir)!

	// Load and return the file
	mut entry := fs.load_entry(file_id)!
	if mut entry is File {
		return &entry
	}
	return error('Failed to create file')
}

// rm removes a file or directory by name
pub fn (mut fs DatabaseVFS) directory_rm(mut dir Directory, name string) ! {
	entry := fs.directory_get_entry(dir, name) or { return error('${name} not found') }
	if entry is Directory {
		if entry.children.len > 0 {
			return error('Directory not empty')
		}
	}

	// get entry from db_metadata
	metadata_bytes := fs.db_metadata.get(fs.id_table[entry.metadata.id] or {
		return error('Failed to delete entry')
	}) or { return error('Failed to delete entry: ${err}') }

	// Handle file data deletion if it's a file
	if entry is File {
		mut file := decode_file_metadata(metadata_bytes)!

		// delete file chunks in data_db
		for id in file.chunk_ids {
			log.debug('[DatabaseVFS] Deleting chunk ${id}')
			fs.db_data.delete(id) or {
				log.error('Failed to delete chunk ${id}: ${err}')
				return error('Failed to delete chunk ${id}: ${err}')
			}
		}

		log.debug('[DatabaseVFS] Deleting file metadata ${file.metadata.id}')
	}

	fs.db_metadata.delete(fs.id_table[entry.metadata.id] or {
		return error('Failed to delete entry')
	}) or { return error('Failed to delete entry: ${err}') }

	// Update children list - make sure we don't remove the wrong child
	dir.children = dir.children.filter(it != entry.metadata.id).clone()
	fs.save_entry(dir) or { return error('Failed to save updated directory.\n${err}') }
}

pub struct MoveDirArgs {
pub mut:
	src_entry_name string     @[required] // source entry name
	dst_entry_name string     @[required] // destination entry name
	dst_parent_dir &Directory @[required] // destination OurDBFSDirectory
}

pub fn (mut fs DatabaseVFS) directory_move(dir_ Directory, args_ MoveDirArgs) !&Directory {
	mut dir := dir_
	mut args := args_
	mut found := false
	mut child_id_to_remove := u32(0)

	// First, make sure we're working with the latest version of the directory
	if updated_dir := fs.load_entry(dir.metadata.id) {
		if updated_dir is Directory {
			dir = updated_dir
		}
	}

	for child_id in dir.children {
		if mut entry := fs.load_entry(child_id) {
			if entry.metadata.name == args.src_entry_name {
				if entry is Symlink {
					return error('${args.src_entry_name} is a symlink')
				}

				found = true
				child_id_to_remove = child_id

				// Handle both files and directories
				if entry is File {
					mut file_entry := entry as File
					file_entry.metadata.name = args.dst_entry_name
					file_entry.metadata.modified_at = time.now().unix()
					file_entry.parent_id = args.dst_parent_dir.metadata.id

					// Ensure no duplicate entries in dst_parent_dir
					if file_entry.metadata.id !in args.dst_parent_dir.children {
						args.dst_parent_dir.children << file_entry.metadata.id
					}

					// Remove from old parent's children before saving the entry
					dir.children = dir.children.filter(it != child_id_to_remove)
					fs.save_entry(dir)!

					fs.save_entry(file_entry)!
					fs.save_entry(args.dst_parent_dir)!

					// Return the destination directory
					return args.dst_parent_dir
				} else {
					// Handle directory
					mut dir_entry := entry as Directory
					dir_entry.metadata.name = args.dst_entry_name
					dir_entry.metadata.modified_at = time.now().unix()
					dir_entry.parent_id = args.dst_parent_dir.metadata.id

					// Recursively update all child paths in moved directory
					fs.move_children_recursive(mut dir_entry)!

					// Ensure no duplicate entries in dst_parent_dir
					if dir_entry.metadata.id !in args.dst_parent_dir.children {
						args.dst_parent_dir.children << dir_entry.metadata.id
					}

					// Remove from old parent's children before saving the entry
					dir.children = dir.children.filter(it != child_id_to_remove)
					fs.save_entry(dir)!

					fs.save_entry(dir_entry)!
					fs.save_entry(args.dst_parent_dir)!

					return &dir_entry
				}
			}
		}
	}

	if !found {
		return error('${args.src_entry_name} not found')
	}

	return error('Unexpected move failure')
}

// Recursive function to update parent_id for all children
fn (mut fs DatabaseVFS) move_children_recursive(mut dir Directory) ! {
	for child in dir.children {
		if mut child_entry := fs.load_entry(child) {
			child_entry.parent_id = dir.metadata.id

			if child_entry is Directory {
				// Recursively move subdirectories
				mut child_entry_ := child_entry as Directory
				fs.move_children_recursive(mut child_entry_)!
			}

			fs.save_entry(child_entry)!
		}
	}
}

pub struct CopyDirArgs {
pub mut:
	src_entry_name string     @[required] // source entry name
	dst_entry_name string     @[required] // destination entry name
	dst_parent_dir &Directory @[required] // destination Directory
}

pub fn (mut fs DatabaseVFS) directory_copy(mut dir Directory, args_ CopyDirArgs) !&Directory {
	mut found := false
	mut args := args_

	// First, make sure we're working with the latest version of the directory
	if updated_dir := fs.load_entry(dir.metadata.id) {
		if updated_dir is Directory {
			dir = updated_dir
		}
	}

	for child_id in dir.children {
		if mut entry := fs.load_entry(child_id) {
			if entry.metadata.name == args.src_entry_name {
				found = true
				if entry is File {
					mut file_entry := entry as File

					mut file_data := []u8{}
					// log.debug('[DatabaseVFS] Got database chunk ids ${chunk_ids}')
					for id in file_entry.chunk_ids {
						// there were chunk ids stored with file so file has data
						if chunk_bytes := fs.db_data.get(id) {
							file_data << chunk_bytes
						} else {
							return error('Failed to fetch file data: ${err}')
						}
					}

					mut new_file := File{
						metadata:  Metadata{
							...file_entry.metadata
							id:   fs.get_next_id()
							name: args.dst_entry_name
						}
						parent_id: args.dst_parent_dir.metadata.id
					}
					fs.save_file(new_file, file_data)!
					args.dst_parent_dir.children << new_file.metadata.id
					fs.save_entry(args.dst_parent_dir)!
					return args.dst_parent_dir
				} else if entry is Symlink {
					mut symlink_entry := entry as Symlink
					mut new_symlink := Symlink{
						...symlink_entry
						parent_id: args.dst_parent_dir.metadata.id
					}
					args.dst_parent_dir.children << new_symlink.metadata.id
					fs.save_entry(args.dst_parent_dir)!
					return args.dst_parent_dir
				}

				mut src_dir := entry as Directory

				// Make sure we have the latest version of the source directory
				if updated_src_dir := fs.load_entry(src_dir.metadata.id) {
					if updated_src_dir is Directory {
						src_dir = updated_src_dir
					}
				}

				// Create a new directory with copied metadata
				mut new_dir := fs.copy_directory(Directory{
					metadata:  Metadata{
						...src_dir.metadata
						name: args.dst_entry_name
					}
					parent_id: args.dst_parent_dir.metadata.id
					children:  []u32{}
				})!

				// Recursively copy children
				fs.copy_children_recursive(mut src_dir, mut new_dir)!

				// Save new directory
				fs.save_entry(new_dir)!
				args.dst_parent_dir.children << new_dir.metadata.id
				fs.save_entry(args.dst_parent_dir)!

				// Make sure to save the source directory too
				fs.save_entry(src_dir)!

				// Reload the source directory to ensure we have the latest version
				if updated_src_dir := fs.load_entry(src_dir.metadata.id) {
					if updated_src_dir is Directory {
						src_dir = updated_src_dir
					}
				}

				// Reload the parent directory to ensure we have the latest version
				if updated_parent_dir := fs.load_entry(dir.metadata.id) {
					if updated_parent_dir is Directory {
						dir = updated_parent_dir
					}
				}

				return new_dir
			}
		}
	}

	if !found {
		return error('${args.src_entry_name} not found')
	}

	return error('Unexpected copy failure')
}

fn (mut fs DatabaseVFS) copy_children_recursive(mut src_dir Directory, mut dst_dir Directory) ! {
	for child_id in src_dir.children {
		if mut entry := fs.load_entry(child_id) {
			match entry {
				Directory {
					mut entry_ := entry as Directory
					mut new_subdir := fs.copy_directory(Directory{
						metadata:  Metadata{
							...entry_.metadata
							id: fs.get_next_id()
						}
						children:  []u32{}
						parent_id: dst_dir.metadata.id
					})!

					fs.copy_children_recursive(mut entry_, mut new_subdir)!
					fs.save_entry(new_subdir)!
					dst_dir.children << new_subdir.metadata.id
				}
				File {
					mut entry_ := entry as File
					mut new_file := fs.copy_file(File{
						metadata:  Metadata{
							...entry_.metadata
							id: fs.get_next_id()
						}
						chunk_ids: entry_.chunk_ids
						parent_id: dst_dir.metadata.id
					})!
					dst_dir.children << new_file.metadata.id
					fs.save_entry(dst_dir)!
				}
				Symlink {
					mut entry_ := entry as Symlink
					mut new_symlink := Symlink{
						metadata:  Metadata{
							...entry_.metadata
							id: fs.get_next_id()
						}
						target:    entry_.target
						parent_id: dst_dir.metadata.id
					}
					fs.save_entry(new_symlink)!
					dst_dir.children << new_symlink.metadata.id
				}
			}
		}
	}

	fs.save_entry(dst_dir)!
}

pub fn (mut fs DatabaseVFS) directory_rename(dir Directory, src_name string, dst_name string) !FSEntry {
	mut found := false

	for child_id in dir.children {
		if mut entry := fs.load_entry(child_id) {
			if entry.metadata.name == src_name {
				found = true

				// Handle different entry types
				if mut entry is Directory {
					// Handle directory rename
					entry.metadata.name = dst_name
					entry.metadata.modified_at = time.now().unix()
					fs.save_entry(entry)!
					return entry
				} else if mut entry is File {
					// Handle file rename
					entry.metadata.name = dst_name
					entry.metadata.modified_at = time.now().unix()
					fs.save_entry(entry)!
					return entry
				} else if mut entry is Symlink {
					// Handle symlink rename
					entry.metadata.name = dst_name
					entry.metadata.modified_at = time.now().unix()
					fs.save_entry(entry)!
					return entry
				}
			}
		}
	}

	if !found {
		return error('${src_name} not found')
	}

	return error('Unexpected rename failure')
}

// get_children returns all immediate children as FSEntry objects
pub fn (mut fs DatabaseVFS) directory_children(mut dir Directory, recursive bool) ![]FSEntry {
	mut entries := []FSEntry{}

	for child_id in dir.children {
		if entry := fs.load_entry(child_id) {
			entries << entry
			if recursive && entry is Directory {
				mut d := entry as Directory
				entries << fs.directory_children(mut d, true)!
			}
		} else {
			panic('Filesystem is corrupted, this should never happen ${err}')
		}
	}
	return entries.clone()
}

// add_symlink adds an existing symlink to this directory
pub fn (mut fs DatabaseVFS) directory_add_symlink(mut dir Directory, mut symlink Symlink) ! {
	// Check if name already exists
	for child_id in dir.children {
		if entry := fs.load_entry(child_id) {
			if entry.metadata.name == symlink.metadata.name {
				return error('Entry with name ${symlink.metadata.name} already exists')
			}
		}
	}

	// Save symlink to DB
	fs.save_entry(symlink)!

	// Add to children
	dir.children << symlink.metadata.id
	fs.save_entry(dir)!
}
