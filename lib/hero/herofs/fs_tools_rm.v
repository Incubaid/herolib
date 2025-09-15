module herofs

// RemoveOptions provides options for remove operations
@[params]
pub struct RemoveOptions {
pub mut:
	recursive    bool // Remove directories and their contents
	delete_blobs bool // Delete underlying blob data (default: false)
	force        bool // Force removal even if files are in multiple directories
}

// // Remove filesystem objects starting from a given path
// pub fn (mut self FsTools) rm(target_path string, opts RemoveOptions) ! {
// 	normalized_path := normalize_path(target_path)

// 	// Try to find what we're removing (file, directory, or symlink)
// 	dir_path, filename := split_path(normalized_path)

// 	if filename == '' {
// 		// We're removing a directory by its path
// 		self.rm_directory_by_path(fs_id, normalized_path, opts)!
// 	} else {
// 		// We're removing a specific item within a directory
// 		parent_dir := self.get_dir_by_absolute_path(fs_id, dir_path)!

// 		// Try to find what we're removing
// 		mut found := false

// 		// Try file first
// 		if file := self.get_file_by_path(parent_dir.id, filename) {
// 			self.rm_file(file.id, opts)!
// 			found = true
// 		}

// 		// Try symlink if file not found
// 		if !found {
// 			// Direct implementation since get_by_path doesn't exist for symlinks
// 			symlinks := self.factory.fs_symlink.list_by_parent(parent_dir.id)!
// 			for symlink in symlinks {
// 				if symlink.name == filename {
// 					self.rm_symlink(symlink.id)!
// 					found = true
// 					break
// 				}
// 			}
// 		}

// 		// Try directory if neither file nor symlink found
// 		if !found {
// 			if subdir := self.find_child_dir_by_name(parent_dir.id, filename) {
// 				self.rm_directory(subdir.id, opts)!
// 				found = true
// 			}
// 		}

// 		if !found {
// 			return error('Path "${target_path}" not found')
// 		}
// 	}
// }

// // Remove a file by ID
// fn (mut self FsTools) rm_file(file_id u32, opts RemoveOptions) ! {
// 	file := self.factory.fs_file.get(file_id)!

// 	// If file is in multiple directories and force is not set, only remove from directories
// 	if file.directories.len > 1 && !opts.force {
// 		return error('File "${file.name}" exists in multiple directories. Use force=true to delete completely or remove from specific directories.')
// 	}

// 	// Collect blob IDs before deleting the file
// 	blob_ids := file.blobs.clone()

// 	// Delete the file
// 	self.factory.fs_file.delete(file_id)!

// 	// Delete blobs if requested
// 	if opts.delete_blobs {
// 		for blob_id in blob_ids {
// 			// Check if blob is used by other files before deleting
// 			if self.is_blob_used_by_other_files(blob_id, file_id)! {
// 				println('Warning: Blob ${blob_id} is used by other files, not deleting')
// 				continue
// 			}
// 			self.factory.fs_blob.delete(blob_id)!
// 		}
// 	}
// }

// // Remove a directory by ID
// fn (mut self FsTools) rm_directory(dir_id u32, opts RemoveOptions) ! {
// 	// Check if directory has children
// 	if self.dir_has_children(dir_id)! {
// 		if !opts.recursive {
// 			dir := self.factory.fs_dir.get(dir_id)!
// 			return error('Directory "${dir.name}" is not empty. Use recursive=true to remove contents.')
// 		}

// 		// Remove all children recursively
// 		self.rm_directory_contents(dir_id, opts)!
// 	}

// 	// Remove the directory itself
// 	self.factory.fs_dir.delete(dir_id)!
// }

// // Remove a directory by path
// fn (mut self FsTools) rm_directory_by_path(dir_path string, opts RemoveOptions) ! {
// 	dir := self.get_dir_by_absolute_path(fs_id, dir_path)!
// 	self.rm_directory(dir.id, opts)!
// }

// // Remove all contents of a directory
// fn (mut self FsTools) rm_directory_contents(dir_id u32, opts RemoveOptions) ! {
// 	// Remove all files in the directory
// 	files := self.list_files_in_dir(dir_id)!
// 	for file in files {
// 		self.rm_file(file.id, opts)!
// 	}

// 	// Remove all symlinks in the directory
// 	symlinks := self.factory.fs_symlink.list_by_parent(dir_id)!
// 	for symlink in symlinks {
// 		self.rm_symlink(symlink.id)!
// 	}

// 	// Remove all subdirectories recursively
// 	subdirs := self.list_child_dirs(dir_id)!
// 	for subdir in subdirs {
// 		self.rm_directory(subdir.id, opts)!
// 	}
// }

// // Remove a symlink by ID
// fn (mut self FsTools) rm_symlink(symlink_id u32) ! {
// 	self.factory.fs_symlink.delete(symlink_id)!
// }
