module vfs_db

import incubaid.herolib.vfs
import incubaid.herolib.core.texttools
import arrays
import log
import os
import time

// Implementation of VFSImplementation interface
pub fn (mut fs DatabaseVFS) root_get() !vfs.FSEntry {
	return fs.root_get_as_dir()!
}

pub fn (mut self DatabaseVFS) file_create(path_ string) !vfs.FSEntry {
	path := '/${path_.trim_left('/').trim_right('/')}'
	// Get parent directory
	parent_path := os.dir(path)
	file_name := os.base(path)
	log.info('[DatabaseVFS] Creating file ${file_name} in ${parent_path} for ${path_}')
	mut parent_dir := self.get_directory(parent_path) or {
		return error('Failed to get parent directory ${parent_path}: ${err}')
	}
	entry := self.directory_touch(mut parent_dir, file_name)!
	log.info('[DatabaseVFS] Created file ${file_name} in ${parent_path}')
	return entry
}

pub fn (mut self DatabaseVFS) file_read(path_ string) ![]u8 {
	path := texttools.path_fix(path_)
	log.info('[DatabaseVFS] Reading file ${path}')
	mut file := self.get_entry(path)!
	log.info('[DatabaseVFS] Got file ${path}')
	if mut file is File {
		mut file_data := []u8{}
		// log.debug('[DatabaseVFS] Got database chunk ids ${chunk_ids}')
		for id in file.chunk_ids {
			log.debug('[DatabaseVFS] Getting chunk ${id}')
			// there were chunk ids stored with file so file has data
			if chunk_bytes := self.db_data.get(id) {
				file_data << chunk_bytes
			} else {
				return error('Failed to fetch file data: ${err}')
			}
		}
		return file_data
	}
	return error('Not a file: ${path}')
}

pub fn (mut self DatabaseVFS) file_write(path_ string, data []u8) ! {
	path := texttools.path_fix(path_)
	if mut entry := self.get_entry(path) {
		if mut entry is File {
			log.info('[DatabaseVFS] Writing ${data.len} bytes to ${path}')
			self.save_file(entry, data) or { return error('Failed to save file: ${err}') }
		} else {
			panic('handle error')
		}
	} else {
		self.file_create(path) or { return error('Failed to create file: ${err}') }
		self.file_write(path, data)!
	}
}

pub fn (mut self DatabaseVFS) file_concatenate(path_ string, data []u8) ! {
	path := texttools.path_fix(path_)
	if data.len == 0 {
		return
	}

	if mut entry := self.get_entry(path) {
		if mut entry is File {
			log.info('[DatabaseVFS] Appending ${data.len} bytes to ${path}')

			// Split new data into chunks of 64 KB
			chunks := arrays.chunk(data, (64 * 1024) - 1)
			mut chunk_ids := entry.chunk_ids.clone() // Start with existing chunk IDs

			// Add new chunks
			for chunk in chunks {
				chunk_id := self.db_data.set(data: chunk) or {
					return error('Failed to save file data chunk: ${err}')
				}
				chunk_ids << chunk_id
				log.debug('[DatabaseVFS] Added chunk ${chunk_id} to ${path}')
			}

			// Update the file with new chunk IDs and updated size
			updated_file := File{
				metadata:  vfs.Metadata{
					...entry.metadata
					size:        entry.metadata.size + u64(data.len)
					modified_at: time.now().unix()
				}
				chunk_ids: chunk_ids
				parent_id: entry.parent_id
			}

			// Encode the file with all its metadata
			metadata_bytes := updated_file.encode()

			// Save the metadata_bytes to metadata_db
			metadata_db_id := self.db_metadata.set(data: metadata_bytes) or {
				return error('Failed to save file metadata on id:${entry.metadata.id}: ${err}')
			}

			self.id_table[entry.metadata.id] = metadata_db_id
		} else {
			return error('Not a file: ${path}')
		}
	} else {
		// If file doesn't exist, create it first
		self.file_create(path) or { return error('Failed to create file: ${err}') }
		// Then write data to it
		self.file_write(path, data)!
	}
}

pub fn (mut self DatabaseVFS) file_delete(path string) ! {
	log.info('[DatabaseVFS] Deleting file ${path}')
	parent_path := os.dir(path)
	file_name := os.base(path)

	mut parent_dir := self.get_directory(parent_path)!
	self.directory_rm(mut parent_dir, file_name) or {
		log.error(err.msg())
		return err
	}
}

pub fn (mut self DatabaseVFS) dir_create(path_ string) !vfs.FSEntry {
	path := '/${path_.trim_left('/').trim_right('/')}'
	log.info('[DatabaseVFS] Creating Directory ${path}')
	parent_path := os.dir(path)
	file_name := os.base(path)
	mut parent_dir := self.get_directory(parent_path)!
	return self.directory_mkdir(mut parent_dir, file_name)!
}

pub fn (mut self DatabaseVFS) dir_list(path string) ![]vfs.FSEntry {
	log.info('[DatabaseVFS] Listing Directory ${path}')
	mut dir := self.get_directory(path)!
	mut entries := []vfs.FSEntry{}
	for child in self.directory_children(mut dir, false)! {
		if child is File {
			entries << vfs.FSEntry(child)
		} else if child is Directory {
			entries << vfs.FSEntry(child)
		} else if child is Symlink {
			entries << vfs.FSEntry(child)
		}
	}
	return entries
}

pub fn (mut self DatabaseVFS) dir_delete(path string) ! {
	log.info('[DatabaseVFS] Deleting Directory ${path}')
	parent_path := os.dir(path)
	dir_name := os.base(path)

	mut parent_dir := self.get_directory(parent_path)!
	self.directory_rm(mut parent_dir, dir_name)!
}

pub fn (mut self DatabaseVFS) link_create(target_path string, link_path string) !vfs.FSEntry {
	log.info('[DatabaseVFS] Creating link ${target_path}')
	parent_path := os.dir(link_path)
	link_name := os.base(link_path)

	mut parent_dir := self.get_directory(parent_path)!

	mut symlink := Symlink{
		metadata:  vfs.Metadata{
			id:          self.get_next_id()
			name:        link_name
			file_type:   .symlink
			created_at:  time.now().unix()
			modified_at: time.now().unix()
			accessed_at: time.now().unix()
			mode:        0o777
			owner:       'user'
			group:       'user'
		}
		target:    target_path
		parent_id: parent_dir.metadata.id
	}

	self.directory_add_symlink(mut parent_dir, mut symlink)!
	return symlink
}

pub fn (mut self DatabaseVFS) link_read(path string) !string {
	log.info('[DatabaseVFS] Reading link ${path}')
	mut entry := self.get_entry(path)!
	if mut entry is Symlink {
		return entry.get_target()!
	}
	return error('Not a symlink: ${path}')
}

pub fn (mut self DatabaseVFS) link_delete(path string) ! {
	log.info('[DatabaseVFS] Deleting link ${path}')
	parent_path := os.dir(path)
	file_name := os.base(path)

	mut parent_dir := self.get_directory(parent_path)!
	self.directory_rm(mut parent_dir, file_name)!
}

pub fn (mut self DatabaseVFS) exists(path_ string) bool {
	path := if !path_.starts_with('/') {
		'/${path_}'
	} else {
		path_
	}
	if path == '/' {
		return true
	}
	// self.print() or {panic(err)}
	log.debug('[DatabaseVFS] Checking path exists ${path}')
	self.get_entry(path) or { return false }
	return true
}

pub fn (mut fs DatabaseVFS) get(path_ string) !vfs.FSEntry {
	path := texttools.path_fix(path_)
	log.info('[DatabaseVFS] Getting filesystem entry ${path}')
	return fs.get_entry(path)!
}

pub fn (mut self DatabaseVFS) rename(old_path string, new_path string) !vfs.FSEntry {
	log.info('[DatabaseVFS] Renaming ${old_path} to ${new_path}')
	src_parent_path := os.dir(old_path)
	src_name := os.base(old_path)
	dst_name := os.base(new_path)

	mut src_parent_dir := self.get_directory(src_parent_path)!
	return self.directory_rename(src_parent_dir, src_name, dst_name)!
}

pub fn (mut self DatabaseVFS) copy(src_path_ string, dst_path_ string) !vfs.FSEntry {
	src_path := texttools.path_fix_absolute(src_path_)
	dst_path := texttools.path_fix_absolute(dst_path_)
	log.info('[DatabaseVFS] Copying ${src_path} to ${dst_path}')
	src_parent_path := os.dir(src_path)
	dst_parent_path := os.dir(dst_path)

	if !self.exists(src_parent_path) {
		return error('${src_parent_path} does not exist')
	}

	if !self.exists(dst_parent_path) {
		return error('${dst_parent_path} does not exist')
	}

	src_name := os.base(src_path)
	dst_name := os.base(dst_path)

	mut src_parent_dir := self.get_directory(src_parent_path)!
	mut dst_parent_dir := self.get_directory(dst_parent_path)!

	if src_parent_dir == dst_parent_dir && src_name == dst_name {
		return error('Moving to the same path not supported')
	}

	return self.directory_copy(mut src_parent_dir,
		src_entry_name: src_name
		dst_entry_name: dst_name
		dst_parent_dir: dst_parent_dir
	)!
}

// copy_file creates a copy of a file
pub fn (mut self DatabaseVFS) copy_file(file File) !&File {
	log.info('[DatabaseVFS] Copying file ${file.metadata.name}')

	// Save the file with its metadata and data
	self.save_file(file, [])!

	// Load the file from the database
	mut entry := self.load_entry(file.metadata.id)!
	if mut entry is File {
		return &entry
	}
	return error('Failed to copy file: entry is not a file')
}

pub fn (mut self DatabaseVFS) move(src_path string, dst_path string) !vfs.FSEntry {
	log.info('[DatabaseVFS] Moving ${texttools.path_fix(src_path)} to ${texttools.path_fix(dst_path)}')
	src_parent_path := os.dir(texttools.path_fix_absolute(src_path))
	dst_parent_path := os.dir(texttools.path_fix_absolute(dst_path))

	if !self.exists(src_parent_path) {
		return error('${src_parent_path} does not exist')
	}

	if !self.exists(dst_parent_path) {
		return error('${dst_parent_path} does not exist')
	}

	src_name := os.base(src_path)
	dst_name := os.base(dst_path)

	mut src_parent_dir := self.get_directory(src_parent_path)!
	mut dst_parent_dir := self.get_directory(dst_parent_path)!

	if src_parent_dir == dst_parent_dir && src_name == dst_name {
		return error('Moving to the same path not supported')
	}

	return self.directory_move(src_parent_dir,
		src_entry_name: src_name
		dst_entry_name: dst_name
		dst_parent_dir: dst_parent_dir
	)!
}

pub fn (mut self DatabaseVFS) delete(path_ string) ! {
	if path_ == '/' || path_ == '' || path_ == '.' {
		return error('cant delete root')
	}
	path := '/${path_.trim_left('/').trim_right('/')}'
	parent_path := os.dir(path)
	file_name := os.base(path)

	mut parent_dir := self.get_directory(parent_path)!

	self.directory_rm(mut parent_dir, file_name) or {
		log.error('[DatabaseVFS] Failed to remove ${file_name} from ${parent_dir.metadata.name}\n${err}')
		return err
	}
}

pub fn (mut self DatabaseVFS) destroy() ! {
	// Nothing to do as the core VFS handles cleanup
}
