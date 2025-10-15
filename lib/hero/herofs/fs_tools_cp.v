module herofs

import incubaid.herolib.hero.db
import os

// CopyOptions provides options for copy operations
@[params]
pub struct CopyOptions {
pub mut:
	recursive  bool = true // Copy directories recursively
	overwrite  bool // Overwrite existing files at destination
	copy_blobs bool // Create new blob copies (true) or reference same blobs (false)
}

// cp copies files and directories from source path to destination
//
// Parameters:
// - src_path: Source path pattern (can use wildcards via FindOptions)
// - dest_path: Destination path
// - find_opts: FindOptions for filtering source items
// - copy_opts: CopyOptions for copy behavior
//
// Example:
// ```
// fs.cp('/src/*.v', '/backup/', FindOptions{recursive: true}, CopyOptions{overwrite: true})!
// ```
pub fn (mut self Fs) cp(src_path string, dest_path string, find_opts FindOptions, copy_opts CopyOptions) ! {
	mut items := self.find(src_path, find_opts) or {
		// Try to get specific file, directory, or symlink by exact path
		mut direct_items := []FindResult{}

		// Try file first
		if src_file := self.get_file_by_absolute_path(src_path) {
			direct_items << FindResult{
				id:          src_file.id
				path:        src_path
				result_type: .file
			}
		} else if src_dir := self.get_dir_by_absolute_path(src_path) {
			direct_items << FindResult{
				id:          src_dir.id
				path:        src_path
				result_type: .directory
			}
		} else if src_symlink := self.get_symlink_by_absolute_path(src_path) {
			direct_items << FindResult{
				id:          src_symlink.id
				path:        src_path
				result_type: .symlink
			}
		}

		if direct_items.len == 0 {
			return error('Source path "${src_path}" not found')
		}
		direct_items
	}

	if items.len == 0 {
		return error('No items found matching pattern: ${src_path}')
	}

	is_dest_dir := dest_path.ends_with('/') || self.get_dir_by_absolute_path(dest_path) or {
		FsDir{}
	} != FsDir{}

	if items.len > 1 && !is_dest_dir {
		return error('Cannot copy multiple items to a single file path: ${dest_path}')
	}

	for item in items {
		match item.result_type {
			.file {
				self.copy_file(item.id, dest_path, copy_opts)!
			}
			.directory {
				if !copy_opts.recursive {
					return error('Cannot copy directory "${item.path}" without recursive option')
				}
				self.copy_directory(item.id, dest_path, copy_opts)!
			}
			.symlink {
				self.copy_symlink(item.id, dest_path, copy_opts)!
			}
		}
	}
}

// copy_file copies a single file to a destination path
fn (mut self Fs) copy_file(file_id u32, dest_path string, opts CopyOptions) ! {
	original_file := self.factory.fs_file.get(file_id)!

	is_dest_dir := dest_path.ends_with('/') || self.get_dir_by_absolute_path(dest_path) or {
		FsDir{}
	} != FsDir{}

	dest_dir_id := if is_dest_dir {
		self.factory.fs_dir.create_path(self.id, dest_path)!
	} else {
		self.factory.fs_dir.create_path(self.id, os.dir(dest_path))!
	}

	file_name := if is_dest_dir { original_file.name } else { os.file_name(dest_path) }

	dest_dir := self.factory.fs_dir.get(dest_dir_id)!
	if existing_file_id := self.find_file_in_dir(file_name, dest_dir) {
		if !opts.overwrite {
			return error('File "${file_name}" already exists in destination')
		}
		self.factory.fs_file.delete(existing_file_id)!
	}

	mut new_blob_ids := []u32{}
	if opts.copy_blobs {
		for blob_id in original_file.blobs {
			o_blob := self.factory.fs_blob.get(blob_id)!
			mut n_blob := self.factory.fs_blob.new(data: o_blob.data)!
			n_blob = self.factory.fs_blob.set(n_blob)!
			new_blob_ids << n_blob.id
		}
	} else {
		new_blob_ids = original_file.blobs.clone()
	}

	mut new_file := self.factory.fs_file.new(
		name:      file_name
		fs_id:     self.id
		blobs:     new_blob_ids
		mime_type: original_file.mime_type
		metadata:  original_file.metadata.clone()
	)!
	new_file = self.factory.fs_file.set(new_file)!
	self.factory.fs_file.add_to_directory(new_file.id, dest_dir_id)!
}

// copy_directory copies a directory and its contents recursively to a destination path
fn (mut self Fs) copy_directory(dir_id u32, dest_path string, opts CopyOptions) ! {
	original_dir := self.factory.fs_dir.get(dir_id)!

	is_dest_dir := dest_path.ends_with('/') || self.get_dir_by_absolute_path(dest_path) or {
		FsDir{}
	} != FsDir{}

	dest_dir_name := if is_dest_dir { original_dir.name } else { os.file_name(dest_path) }

	parent_dest_dir_id := if is_dest_dir {
		self.factory.fs_dir.create_path(self.id, dest_path)!
	} else {
		self.factory.fs_dir.create_path(self.id, os.dir(dest_path))!
	}

	parent_dest_dir := self.factory.fs_dir.get(parent_dest_dir_id)!
	if existing_dir_id := self.find_dir_in_dir(dest_dir_name, parent_dest_dir) {
		if opts.recursive {
			self.copy_directory_contents(dir_id, existing_dir_id, opts)!
			return
		}

		if !opts.overwrite {
			return error('Directory "${dest_dir_name}" already exists in destination')
		}
		self.factory.fs_dir.delete(existing_dir_id)!
	}

	mut new_dir := self.factory.fs_dir.new(
		name:        dest_dir_name
		fs_id:       self.id
		parent_id:   parent_dest_dir_id
		description: original_dir.description
	)!
	new_dir = self.factory.fs_dir.set(new_dir)!

	mut parent_dir := self.factory.fs_dir.get(parent_dest_dir_id)!
	if new_dir.id !in parent_dir.directories {
		parent_dir.directories << new_dir.id
		self.factory.fs_dir.set(parent_dir)!
	}

	self.copy_directory_contents(dir_id, new_dir.id, opts)!
}

// copy_directory_contents copies the contents of one directory to another
fn (mut self Fs) copy_directory_contents(src_dir_id u32, dest_dir_id u32, opts CopyOptions) ! {
	src_dir := self.factory.fs_dir.get(src_dir_id)!

	for file_id in src_dir.files {
		self.copy_file(file_id, dest_dir_id.str(), opts)!
	}

	for subdir_id in src_dir.directories {
		self.copy_directory(subdir_id, dest_dir_id.str(), opts)!
	}

	for symlink_id in src_dir.symlinks {
		self.copy_symlink(symlink_id, dest_dir_id.str(), opts)!
	}
}

// copy_symlink copies a symbolic link to a destination path
fn (mut self Fs) copy_symlink(symlink_id u32, dest_path string, opts CopyOptions) ! {
	original_symlink := self.factory.fs_symlink.get(symlink_id)!

	is_dest_dir := dest_path.ends_with('/') || self.get_dir_by_absolute_path(dest_path) or {
		FsDir{}
	} != FsDir{}

	dest_dir_id := if is_dest_dir {
		self.factory.fs_dir.create_path(self.id, dest_path)!
	} else {
		self.factory.fs_dir.create_path(self.id, os.dir(dest_path))!
	}

	symlink_name := if is_dest_dir { original_symlink.name } else { os.file_name(dest_path) }

	dest_dir := self.factory.fs_dir.get(dest_dir_id)!
	if existing_symlink_id := self.find_symlink_in_dir(symlink_name, dest_dir) {
		if !opts.overwrite {
			return error('Symlink "${symlink_name}" already exists')
		}
		self.factory.fs_symlink.delete(existing_symlink_id)!
	}

	mut new_symlink := self.factory.fs_symlink.new(
		name:        symlink_name
		fs_id:       self.id
		parent_id:   dest_dir_id
		target_id:   original_symlink.target_id
		target_type: original_symlink.target_type
		description: original_symlink.description
	)!
	new_symlink = self.factory.fs_symlink.set(new_symlink)!

	mut parent := self.factory.fs_dir.get(dest_dir_id)!
	parent.symlinks << new_symlink.id
	self.factory.fs_dir.set(parent)!
}

// find_file_in_dir finds a file in a directory by name and returns its ID
fn (mut self Fs) find_file_in_dir(file_name string, dir FsDir) ?u32 {
	for file_id in dir.files {
		file := self.factory.fs_file.get(file_id) or { continue }
		if file.name == file_name {
			return file_id
		}
	}
	return none
}

// find_dir_in_dir finds a directory in a directory by name and returns its ID
fn (mut self Fs) find_dir_in_dir(dir_name string, dir FsDir) ?u32 {
	for did in dir.directories {
		d := self.factory.fs_dir.get(did) or { continue }
		if d.name == dir_name {
			return did
		}
	}
	return none
}

// find_symlink_in_dir finds a symlink in a directory by name and returns its ID
fn (mut self Fs) find_symlink_in_dir(symlink_name string, dir FsDir) ?u32 {
	for symlink_id in dir.symlinks {
		symlink := self.factory.fs_symlink.get(symlink_id) or { continue }
		if symlink.name == symlink_name {
			return symlink_id
		}
	}
	return none
}

// get_dir_path returns the absolute path for a given directory ID.
pub fn (mut self Fs) get_dir_path(dir_id u32) !string {
	if dir_id == self.root_dir_id {
		return '/'
	}
	mut path := ''
	mut current_id := dir_id
	for {
		dir := self.factory.fs_dir.get(current_id)!
		if dir.id == self.root_dir_id {
			break
		}
		path = '/' + dir.name + path
		if dir.parent_id == 0 {
			break
		}
		current_id = dir.parent_id
	}
	return if path == '' { '/' } else { path }
}
