module herofs

// MoveOptions provides options for move operations
@[params]
pub struct MoveOptions {
pub mut:
	overwrite       bool // Overwrite existing files at destination
	follow_symlinks bool // Follow symlinks instead of moving them
}

// // Move filesystem objects from source path to destination path
// pub fn (mut self FsTools) mv(source_path string, dest_path string, opts MoveOptions) ! {
// 	normalized_source := normalize_path(source_path)
// 	normalized_dest := normalize_path(dest_path)

// 	// Determine what we're moving
// 	source_dir_path, source_filename := split_path(normalized_source)

// 	if source_filename == '' {
// 		// We're moving a directory
// 		source_dir := self.get_dir_by_absolute_path(fs_id, normalized_source)!
// 		self.mv_directory(fs_id, source_dir.id, normalized_dest)!
// 	} else {
// 		// We're moving a specific item
// 		source_parent_dir := self.get_dir_by_absolute_path(fs_id, source_dir_path)!

// 		// Try to find what we're moving
// 		mut found := false

// 		// Try file first
// 		if file := self.get_file_by_path(source_parent_dir.id, source_filename) {
// 			self.mv_file(fs_id, file.id, normalized_dest, opts)!
// 			found = true
// 		}

// 		// Try symlink if file not found
// 		if !found {
// 			// Direct implementation since get_by_path doesn't exist for symlinks
// 			symlinks := self.factory.fs_symlink.list_by_parent(source_parent_dir.id)!
// 			for symlink in symlinks {
// 				if symlink.name == source_filename {
// 					self.mv_symlink(fs_id, symlink.id, normalized_dest, opts)!
// 					found = true
// 					break
// 				}
// 			}
// 		}

// 		// Try directory if neither file nor symlink found
// 		if !found {
// 			if subdir := self.find_child_dir_by_name(source_parent_dir.id, source_filename) {
// 				self.mv_directory(fs_id, subdir.id, normalized_dest)!
// 				found = true
// 			}
// 		}

// 		if !found {
// 			return error('Source path "${source_path}" not found')
// 		}
// 	}
// }

// // Move a file to destination path
// fn (mut self FsTools) mv_file(file_id u32, dest_path string, opts MoveOptions) ! {
// 	source_file := self.factory.fs_file.get(file_id)!

// 	// Determine destination directory and filename
// 	dest_dir_path, mut dest_filename := split_path(dest_path)
// 	if dest_filename == '' {
// 		dest_filename = source_file.name
// 	}

// 	// Ensure destination directory exists
// 	dest_dir_id := self.create_dir_path(fs_id, dest_dir_path)!

// 	// Check if destination file already exists
// 	if existing_file := self.get_file_by_path(dest_dir_id, dest_filename) {
// 		if !opts.overwrite {
// 			return error('Destination file "${dest_path}" already exists. Use overwrite=true to replace.')
// 		}
// 		// Remove existing file
// 		self.factory.fs_file.delete(existing_file.id)!
// 	}

// 	// Update file name if it's different
// 	// Direct implementation since rename doesn't exist for files
// 	if dest_filename != source_file.name {
// 		source_file.name = dest_filename
// 		self.factory.fs_file.set(source_file)!
// 	}

// 	// Move file to new directory (replace all directory associations)
// 	// Direct implementation since move doesn't exist for files
// 	source_file.directories = [dest_dir_id]
// 	self.factory.fs_file.set(source_file)!
// }

// // Move a symlink to destination path
// fn (mut self FsTools) mv_symlink(symlink_id u32, dest_path string, opts MoveOptions) ! {
// 	source_symlink := self.factory.fs_symlink.get(symlink_id)!

// 	if opts.follow_symlinks {
// 		// Follow the symlink and move its target instead
// 		if source_symlink.target_type == .file {
// 			self.mv_file(fs_id, source_symlink.target_id, dest_path, opts)!
// 		} else if source_symlink.target_type == .directory {
// 			self.mv_directory(fs_id, source_symlink.target_id, dest_path)!
// 		}
// 		// Remove the original symlink
// 		self.factory.fs_symlink.delete(symlink_id)!
// 		return
// 	}

// 	// Move the symlink itself
// 	dest_dir_path, mut dest_filename := split_path(dest_path)
// 	if dest_filename == '' {
// 		dest_filename = source_symlink.name
// 	}

// 	// Ensure destination directory exists
// 	dest_dir_id := self.create_dir_path(fs_id, dest_dir_path)!

// 	// Check if destination symlink already exists
// 	// Direct implementation since get_by_path doesn't exist for symlinks
// 	symlinks := self.factory.fs_symlink.list_by_parent(dest_dir_id)!
// 	for existing_symlink in symlinks {
// 		if existing_symlink.name == dest_filename {
// 			if !opts.overwrite {
// 				return error('Destination symlink "${dest_path}" already exists. Use overwrite=true to replace.')
// 			}
// 			self.factory.fs_symlink.delete(existing_symlink.id)!
// 			break
// 		}
// 	}

// 	// Update symlink name if it's different
// 	// Direct implementation since rename doesn't exist for symlinks
// 	if dest_filename != source_symlink.name {
// 		source_symlink.name = dest_filename
// 		self.factory.fs_symlink.set(source_symlink)!
// 	}

// 	// Move symlink to new parent directory
// 	// Direct implementation since move doesn't exist for symlinks
// 	source_symlink.parent_id = dest_dir_id
// 	self.factory.fs_symlink.set(source_symlink)!
// }

// // Move a directory to destination path
// fn (mut self FsTools) mv_directory(source_dir_id u32, dest_path string) ! {
// 	source_dir := self.factory.fs_dir.get(source_dir_id)!

// 	// Parse destination path
// 	dest_parent_path, mut dest_dirname := split_path(dest_path)
// 	if dest_dirname == '' {
// 		dest_dirname = source_dir.name
// 	}

// 	// Ensure destination parent directory exists
// 	dest_parent_id := if dest_parent_path == '/' {
// 		// Moving to root level, find root directory
// 		fs := self.factory.fs.get(fs_id)!
// 		fs.root_dir_id
// 	} else {
// 		self.create_dir_path(fs_id, dest_parent_path)!
// 	}

// 	// Update directory name if it's different
// 	// Direct implementation since rename doesn't exist for directories
// 	if dest_dirname != source_dir.name {
// 		source_dir.name = dest_dirname
// 		self.factory.fs_dir.set(source_dir)!
// 	}

// 	// Move directory to new parent
// 	// Direct implementation since move doesn't exist for directories
// 	source_dir.parent_id = dest_parent_id
// 	self.factory.fs_dir.set(source_dir)!
// }
