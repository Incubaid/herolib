module herofs

// CopyOptions provides options for copy operations
@[params]
pub struct CopyOptions {
pub mut:
	recursive       bool = true // Copy directories recursively
	preserve_links  bool = true // Preserve symbolic links as links
	overwrite       bool // Overwrite existing files
	follow_symlinks bool // Follow symlinks instead of copying them
}

// // Copy filesystem objects from source path to destination path
// pub fn (mut self FsTools) cp(source_path string, dest_path string, opts CopyOptions) ! {
// 	normalized_source := normalize_path(source_path)
// 	normalized_dest := normalize_path(dest_path)

// 	// Determine what we're copying
// 	source_dir_path, source_filename := split_path(normalized_source)

// 	if source_filename == '' {
// 		// We're copying a directory
// 		source_dir := self.get_dir_by_absolute_path(fs_id, normalized_source)!
// 		self.cp_directory(fs_id, source_dir.id, normalized_source, normalized_dest, opts)!
// 	} else {
// 		// We're copying a specific item
// 		source_parent_dir := self.get_dir_by_absolute_path(fs_id, source_dir_path)!

// 		// Try to find what we're copying
// 		mut found := false

// 		// Try file first
// 		if file := self.get_file_by_path(source_parent_dir.id, source_filename) {
// 			self.cp_file(fs_id, file.id, normalized_dest, opts)!
// 			found = true
// 		}

// 		// Try symlink if file not found
// 		if !found {
// 			// Direct implementation since get_by_path doesn't exist for symlinks
// 			symlinks := self.factory.fs_symlink.list_by_parent(source_parent_dir.id)!
// 			for symlink in symlinks {
// 				if symlink.name == source_filename {
// 					self.cp_symlink(fs_id, symlink.id, normalized_dest, opts)!
// 					found = true
// 					break
// 				}
// 			}
// 		}

// 		// Try directory if neither file nor symlink found
// 		if !found {
// 			if subdir := self.find_child_dir_by_name(source_parent_dir.id, source_filename) {
// 				self.cp_directory(fs_id, subdir.id, normalized_source, normalized_dest,
// 					opts)!
// 				found = true
// 			}
// 		}

// 		if !found {
// 			return error('Source path "${source_path}" not found')
// 		}
// 	}
// }

// // Copy a file to destination path
// fn (mut self FsTools) cp_file(file_id u32, dest_path string, opts CopyOptions) ! {
// 	source_file := self.factory.fs_file.get(file_id)!

// 	// Determine destination directory and filename
// 	dest_dir_path, mut dest_filename := split_path(dest_path)
// 	if dest_filename == '' {
// 		dest_filename = source_file.name
// 	}

// 	// Ensure destination directory exists (create if needed)
// 	dest_dir_id := self.create_dir_path(fs_id, dest_dir_path)!

// 	// Check if destination file already exists
// 	if existing_file := self.get_file_by_path(dest_dir_id, dest_filename) {
// 		if !opts.overwrite {
// 			return error('Destination file "${dest_path}" already exists. Use overwrite=true to replace.')
// 		}
// 		// Remove existing file
// 		self.factory.fs_file.delete(existing_file.id)!
// 	}

// 	// Create new file with same content (reuse blobs)
// 	new_file := self.factory.fs_file.new(
// 		name:        dest_filename
// 		fs_id:       fs_id
// 		directories: [dest_dir_id]
// 		blobs:       source_file.blobs.clone()
// 		mime_type:   source_file.mime_type
// 		checksum:    source_file.checksum
// 		metadata:    source_file.metadata.clone()
// 		description: source_file.description
// 	)!

// 	self.factory.fs_file.set(new_file)!
// }

// // Copy a symlink to destination path
// fn (mut self FsTools) cp_symlink(symlink_id u32, dest_path string, opts CopyOptions) ! {
// 	source_symlink := self.factory.fs_symlink.get(symlink_id)!

// 	if opts.follow_symlinks {
// 		// Follow the symlink and copy its target instead
// 		if source_symlink.target_type == .file {
// 			self.cp_file(fs_id, source_symlink.target_id, dest_path, opts)!
// 		} else if source_symlink.target_type == .directory {
// 			self.cp_directory(fs_id, source_symlink.target_id, '', dest_path, opts)!
// 		}
// 		return
// 	}

// 	// Copy the symlink itself
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

// 	// Create new symlink
// 	new_symlink := self.factory.fs_symlink.new(
// 		name:        dest_filename
// 		fs_id:       fs_id
// 		parent_id:   dest_dir_id
// 		target_id:   source_symlink.target_id
// 		target_type: source_symlink.target_type
// 		description: source_symlink.description
// 	)!

// 	self.factory.fs_symlink.set(new_symlink)!
// }

// // Copy a directory to destination path
// fn (mut self FsTools) cp_directory(source_dir_id u32, source_path string, dest_path string, opts CopyOptions) ! {
// 	source_dir := self.factory.fs_dir.get(source_dir_id)!

// 	// Create destination directory
// 	dest_dir_id := self.create_dir_path(fs_id, dest_path)!

// 	if !opts.recursive {
// 		return
// 	}

// 	// Copy all files in the source directory
// 	files := self.list_files_in_dir(source_dir_id)!
// 	for file in files {
// 		file_dest_path := join_path(dest_path, file.name)
// 		self.cp_file(fs_id, file.id, file_dest_path, opts)!
// 	}

// 	// Copy all symlinks in the source directory
// 	if opts.preserve_links {
// 		symlinks := self.factory.fs_symlink.list_by_parent(source_dir_id)!
// 		for symlink in symlinks {
// 			symlink_dest_path := join_path(dest_path, symlink.name)
// 			self.cp_symlink(fs_id, symlink.id, symlink_dest_path, opts)!
// 		}
// 	}

// 	// Copy all subdirectories recursively
// 	subdirs := self.list_child_dirs(source_dir_id)!
// 	for subdir in subdirs {
// 		subdir_source_path := if source_path == '' {
// 			subdir.name
// 		} else {
// 			join_path(source_path, subdir.name)
// 		}
// 		subdir_dest_path := join_path(dest_path, subdir.name)
// 		self.cp_directory(fs_id, subdir.id, subdir_source_path, subdir_dest_path, opts)!
// 	}
// }
