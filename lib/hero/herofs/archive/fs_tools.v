module herofs

import freeflowuniverse.herolib.data.ourtime

// FindResult represents the result of a filesystem search
pub struct FindResult {
pub mut:
	result_type FindResultType
	id          u32
	path        string
	name        string
}

// FindResultType indicates what type of filesystem object was found
pub enum FindResultType {
	file
	directory
	symlink
}

// FindOptions provides options for filesystem search operations
@[params]
pub struct FindOptions {
pub mut:
	recursive        bool = true
	include_patterns []string // File/directory name patterns to include (e.g. ['*.v', 'doc*'])
	exclude_patterns []string // File/directory name patterns to exclude
	max_depth        int = -1 // Maximum depth to search (-1 for unlimited)
	follow_symlinks  bool // Whether to follow symbolic links during search
}

// CopyOptions provides options for copy operations
@[params]
pub struct CopyOptions {
pub mut:
	recursive       bool = true // Copy directories recursively
	preserve_links  bool = true // Preserve symbolic links as links
	overwrite       bool // Overwrite existing files
	follow_symlinks bool // Follow symlinks instead of copying them
}

// RemoveOptions provides options for remove operations
@[params]
pub struct RemoveOptions {
pub mut:
	recursive    bool // Remove directories and their contents
	delete_blobs bool // Delete underlying blob data (default: false)
	force        bool // Force removal even if files are in multiple directories
}

// MoveOptions provides options for move operations
@[params]
pub struct MoveOptions {
pub mut:
	overwrite       bool // Overwrite existing files at destination
	follow_symlinks bool // Follow symlinks instead of moving them
}

// FsTools provides high-level filesystem operations
pub struct FsTools {
pub mut:
	factory &FsFactory @[skip; str: skip]
}

// Create a new FsTools instance
pub fn (factory &FsFactory) tools() FsTools {
	return FsTools{
		factory: factory
	}
}

// Helper function to check if name matches include/exclude patterns
fn matches_pattern(name string, patterns []string) bool {
	if patterns.len == 0 {
		return true // No patterns means include everything
	}

	for pattern in patterns {
		if pattern.contains('*') {
			prefix := pattern.all_before('*')
			suffix := pattern.all_after('*')

			if prefix == '' && suffix == '' {
				return true // Pattern is just "*"
			} else if prefix == '' {
				if name.ends_with(suffix) {
					return true
				}
			} else if suffix == '' {
				if name.starts_with(prefix) {
					return true
				}
			} else {
				if name.starts_with(prefix) && name.ends_with(suffix) {
					return true
				}
			}
		} else if name == pattern {
			return true // Exact match
		}
	}

	return false
}

// Check if item should be included based on patterns
fn should_include(name string, include_patterns []string, exclude_patterns []string) bool {
	// First apply include patterns (if empty, include everything)
	if !matches_pattern(name, include_patterns) && include_patterns.len > 0 {
		return false
	}

	// Then apply exclude patterns
	if matches_pattern(name, exclude_patterns) && exclude_patterns.len > 0 {
		return false
	}

	return true
}

// Normalize path by removing trailing slashes and handling edge cases
fn normalize_path(path string) string {
	if path == '' || path == '/' {
		return '/'
	}
	return path.trim_right('/')
}

// Split path into directory and filename parts
fn split_path(path string) (string, string) {
	normalized := normalize_path(path)
	if normalized == '/' {
		return '/', ''
	}

	mut dir_path := normalized.all_before_last('/')
	filename := normalized.all_after_last('/')

	if dir_path == '' {
		dir_path = '/'
	}

	return dir_path, filename
}

// Get the parent path of a given path
fn parent_path(path string) string {
	normalized := normalize_path(path)
	if normalized == '/' {
		return '/'
	}

	parent := normalized.all_before_last('/')
	if parent == '' {
		return '/'
	}
	return parent
}

// Join path components
fn join_path(base string, component string) string {
	normalized_base := normalize_path(base)
	if normalized_base == '/' {
		return '/' + component
	}
	return normalized_base + '/' + component
}

// Find filesystem objects starting from a given path
pub fn (mut self FsTools) find(fs_id u32, start_path string, opts FindOptions) ![]FindResult {
	mut results := []FindResult{}

	// Get the starting directory
	start_dir := self.get_dir_by_absolute_path(fs_id, start_path)!

	// Start recursive search
	self.find_recursive(fs_id, start_dir.id, start_path, opts, mut results, 0)!

	return results
}

// Internal recursive function for find operation
fn (mut self FsTools) find_recursive(fs_id u32, dir_id u32, current_path string, opts FindOptions, mut results []FindResult, current_depth int) ! {
	// Check depth limit
	if opts.max_depth >= 0 && current_depth > opts.max_depth {
		return
	}

	// Get current directory info
	current_dir := self.factory.fs_dir.get(dir_id)!

	// Check if current directory matches search criteria
	if should_include(current_dir.name, opts.include_patterns, opts.exclude_patterns) {
		results << FindResult{
			result_type: .directory
			id:          dir_id
			path:        current_path
			name:        current_dir.name
		}
	}

	// Get files in current directory
	files := self.list_files_in_dir(dir_id)!
	for file in files {
		if should_include(file.name, opts.include_patterns, opts.exclude_patterns) {
			file_path := join_path(current_path, file.name)
			results << FindResult{
				result_type: .file
				id:          file.id
				path:        file_path
				name:        file.name
			}
		}
	}

	// Get symlinks in current directory
	symlinks := self.factory.fs_symlink.list_by_parent(dir_id)!
	for symlink in symlinks {
		if should_include(symlink.name, opts.include_patterns, opts.exclude_patterns) {
			symlink_path := join_path(current_path, symlink.name)
			results << FindResult{
				result_type: .symlink
				id:          symlink.id
				path:        symlink_path
				name:        symlink.name
			}
		}

		// Follow symlinks if requested and they point to directories
		if opts.follow_symlinks && opts.recursive && symlink.target_type == .directory {
			// Check if symlink is not broken
			if !self.factory.fs_symlink.is_broken(symlink.id)! {
				symlink_path := join_path(current_path, symlink.name)
				self.find_recursive(fs_id, symlink.target_id, symlink_path, opts, mut
					results, current_depth + 1)!
			}
		}
	}

	// Process subdirectories if recursive
	if opts.recursive {
		subdirs := self.list_child_dirs(dir_id)!
		for subdir in subdirs {
			subdir_path := join_path(current_path, subdir.name)
			self.find_recursive(fs_id, subdir.id, subdir_path, opts, mut results, current_depth + 1)!
		}
	}
}

// Remove filesystem objects starting from a given path
pub fn (mut self FsTools) rm(fs_id u32, target_path string, opts RemoveOptions) ! {
	normalized_path := normalize_path(target_path)

	// Try to find what we're removing (file, directory, or symlink)
	dir_path, filename := split_path(normalized_path)

	if filename == '' {
		// We're removing a directory by its path
		self.rm_directory_by_path(fs_id, normalized_path, opts)!
	} else {
		// We're removing a specific item within a directory
		parent_dir := self.get_dir_by_absolute_path(fs_id, dir_path)!

		// Try to find what we're removing
		mut found := false

		// Try file first
		if file := self.get_file_by_path(parent_dir.id, filename) {
			self.rm_file(file.id, opts)!
			found = true
		}

		// Try symlink if file not found
		if !found {
			// Direct implementation since get_by_path doesn't exist for symlinks
			symlinks := self.factory.fs_symlink.list_by_parent(parent_dir.id)!
			for symlink in symlinks {
				if symlink.name == filename {
					self.rm_symlink(symlink.id)!
					found = true
					break
				}
			}
		}

		// Try directory if neither file nor symlink found
		if !found {
			if subdir := self.find_child_dir_by_name(parent_dir.id, filename) {
				self.rm_directory(subdir.id, opts)!
				found = true
			}
		}

		if !found {
			return error('Path "${target_path}" not found')
		}
	}
}

// Remove a file by ID
fn (mut self FsTools) rm_file(file_id u32, opts RemoveOptions) ! {
	file := self.factory.fs_file.get(file_id)!

	// If file is in multiple directories and force is not set, only remove from directories
	if file.directories.len > 1 && !opts.force {
		return error('File "${file.name}" exists in multiple directories. Use force=true to delete completely or remove from specific directories.')
	}

	// Collect blob IDs before deleting the file
	blob_ids := file.blobs.clone()

	// Delete the file
	self.factory.fs_file.delete(file_id)!

	// Delete blobs if requested
	if opts.delete_blobs {
		for blob_id in blob_ids {
			// Check if blob is used by other files before deleting
			if self.is_blob_used_by_other_files(blob_id, file_id)! {
				println('Warning: Blob ${blob_id} is used by other files, not deleting')
				continue
			}
			self.factory.fs_blob.delete(blob_id)!
		}
	}
}

// Remove a directory by ID
fn (mut self FsTools) rm_directory(dir_id u32, opts RemoveOptions) ! {
	// Check if directory has children
	if self.dir_has_children(dir_id)! {
		if !opts.recursive {
			dir := self.factory.fs_dir.get(dir_id)!
			return error('Directory "${dir.name}" is not empty. Use recursive=true to remove contents.')
		}

		// Remove all children recursively
		self.rm_directory_contents(dir_id, opts)!
	}

	// Remove the directory itself
	self.factory.fs_dir.delete(dir_id)!
}

// Remove a directory by path
fn (mut self FsTools) rm_directory_by_path(fs_id u32, dir_path string, opts RemoveOptions) ! {
	dir := self.get_dir_by_absolute_path(fs_id, dir_path)!
	self.rm_directory(dir.id, opts)!
}

// Remove all contents of a directory
fn (mut self FsTools) rm_directory_contents(dir_id u32, opts RemoveOptions) ! {
	// Remove all files in the directory
	files := self.list_files_in_dir(dir_id)!
	for file in files {
		self.rm_file(file.id, opts)!
	}

	// Remove all symlinks in the directory
	symlinks := self.factory.fs_symlink.list_by_parent(dir_id)!
	for symlink in symlinks {
		self.rm_symlink(symlink.id)!
	}

	// Remove all subdirectories recursively
	subdirs := self.list_child_dirs(dir_id)!
	for subdir in subdirs {
		self.rm_directory(subdir.id, opts)!
	}
}

// Remove a symlink by ID
fn (mut self FsTools) rm_symlink(symlink_id u32) ! {
	self.factory.fs_symlink.delete(symlink_id)!
}

// Check if a blob is used by other files (excluding the specified file_id)
fn (mut self FsTools) is_blob_used_by_other_files(blob_id u32, exclude_file_id u32) !bool {
	// This is a simple but potentially expensive check
	// In a production system, you might want to maintain reverse indices
	all_files := self.list_all_files()!
	for file in all_files {
		if file.id != exclude_file_id && blob_id in file.blobs {
			return true
		}
	}
	return false
}

// Copy filesystem objects from source path to destination path
pub fn (mut self FsTools) cp(fs_id u32, source_path string, dest_path string, opts CopyOptions) ! {
	normalized_source := normalize_path(source_path)
	normalized_dest := normalize_path(dest_path)

	// Determine what we're copying
	source_dir_path, source_filename := split_path(normalized_source)

	if source_filename == '' {
		// We're copying a directory
		source_dir := self.get_dir_by_absolute_path(fs_id, normalized_source)!
		self.cp_directory(fs_id, source_dir.id, normalized_source, normalized_dest, opts)!
	} else {
		// We're copying a specific item
		source_parent_dir := self.get_dir_by_absolute_path(fs_id, source_dir_path)!

		// Try to find what we're copying
		mut found := false

		// Try file first
		if file := self.get_file_by_path(source_parent_dir.id, source_filename) {
			self.cp_file(fs_id, file.id, normalized_dest, opts)!
			found = true
		}

		// Try symlink if file not found
		if !found {
			// Direct implementation since get_by_path doesn't exist for symlinks
			symlinks := self.factory.fs_symlink.list_by_parent(source_parent_dir.id)!
			for symlink in symlinks {
				if symlink.name == source_filename {
					self.cp_symlink(fs_id, symlink.id, normalized_dest, opts)!
					found = true
					break
				}
			}
		}

		// Try directory if neither file nor symlink found
		if !found {
			if subdir := self.find_child_dir_by_name(source_parent_dir.id, source_filename) {
				self.cp_directory(fs_id, subdir.id, normalized_source, normalized_dest,
					opts)!
				found = true
			}
		}

		if !found {
			return error('Source path "${source_path}" not found')
		}
	}
}

// Copy a file to destination path
fn (mut self FsTools) cp_file(fs_id u32, file_id u32, dest_path string, opts CopyOptions) ! {
	source_file := self.factory.fs_file.get(file_id)!

	// Determine destination directory and filename
	dest_dir_path, mut dest_filename := split_path(dest_path)
	if dest_filename == '' {
		dest_filename = source_file.name
	}

	// Ensure destination directory exists (create if needed)
	dest_dir_id := self.create_dir_path(fs_id, dest_dir_path)!

	// Check if destination file already exists
	if existing_file := self.get_file_by_path(dest_dir_id, dest_filename) {
		if !opts.overwrite {
			return error('Destination file "${dest_path}" already exists. Use overwrite=true to replace.')
		}
		// Remove existing file
		self.factory.fs_file.delete(existing_file.id)!
	}

	// Create new file with same content (reuse blobs)
	new_file := self.factory.fs_file.new(
		name:        dest_filename
		fs_id:       fs_id
		directories: [dest_dir_id]
		blobs:       source_file.blobs.clone()
		mime_type:   source_file.mime_type
		checksum:    source_file.checksum
		metadata:    source_file.metadata.clone()
		description: source_file.description
	)!

	self.factory.fs_file.set(new_file)!
}

// Copy a symlink to destination path
fn (mut self FsTools) cp_symlink(fs_id u32, symlink_id u32, dest_path string, opts CopyOptions) ! {
	source_symlink := self.factory.fs_symlink.get(symlink_id)!

	if opts.follow_symlinks {
		// Follow the symlink and copy its target instead
		if source_symlink.target_type == .file {
			self.cp_file(fs_id, source_symlink.target_id, dest_path, opts)!
		} else if source_symlink.target_type == .directory {
			self.cp_directory(fs_id, source_symlink.target_id, '', dest_path, opts)!
		}
		return
	}

	// Copy the symlink itself
	dest_dir_path, mut dest_filename := split_path(dest_path)
	if dest_filename == '' {
		dest_filename = source_symlink.name
	}

	// Ensure destination directory exists
	dest_dir_id := self.create_dir_path(fs_id, dest_dir_path)!

	// Check if destination symlink already exists
	// Direct implementation since get_by_path doesn't exist for symlinks
	symlinks := self.factory.fs_symlink.list_by_parent(dest_dir_id)!
	for existing_symlink in symlinks {
		if existing_symlink.name == dest_filename {
			if !opts.overwrite {
				return error('Destination symlink "${dest_path}" already exists. Use overwrite=true to replace.')
			}
			self.factory.fs_symlink.delete(existing_symlink.id)!
			break
		}
	}

	// Create new symlink
	new_symlink := self.factory.fs_symlink.new(
		name:        dest_filename
		fs_id:       fs_id
		parent_id:   dest_dir_id
		target_id:   source_symlink.target_id
		target_type: source_symlink.target_type
		description: source_symlink.description
	)!

	self.factory.fs_symlink.set(new_symlink)!
}

// Copy a directory to destination path
fn (mut self FsTools) cp_directory(fs_id u32, source_dir_id u32, source_path string, dest_path string, opts CopyOptions) ! {
	source_dir := self.factory.fs_dir.get(source_dir_id)!

	// Create destination directory
	dest_dir_id := self.create_dir_path(fs_id, dest_path)!

	if !opts.recursive {
		return
	}

	// Copy all files in the source directory
	files := self.list_files_in_dir(source_dir_id)!
	for file in files {
		file_dest_path := join_path(dest_path, file.name)
		self.cp_file(fs_id, file.id, file_dest_path, opts)!
	}

	// Copy all symlinks in the source directory
	if opts.preserve_links {
		symlinks := self.factory.fs_symlink.list_by_parent(source_dir_id)!
		for symlink in symlinks {
			symlink_dest_path := join_path(dest_path, symlink.name)
			self.cp_symlink(fs_id, symlink.id, symlink_dest_path, opts)!
		}
	}

	// Copy all subdirectories recursively
	subdirs := self.list_child_dirs(source_dir_id)!
	for subdir in subdirs {
		subdir_source_path := if source_path == '' {
			subdir.name
		} else {
			join_path(source_path, subdir.name)
		}
		subdir_dest_path := join_path(dest_path, subdir.name)
		self.cp_directory(fs_id, subdir.id, subdir_source_path, subdir_dest_path, opts)!
	}
}

// Move filesystem objects from source path to destination path
pub fn (mut self FsTools) mv(fs_id u32, source_path string, dest_path string, opts MoveOptions) ! {
	normalized_source := normalize_path(source_path)
	normalized_dest := normalize_path(dest_path)

	// Determine what we're moving
	source_dir_path, source_filename := split_path(normalized_source)

	if source_filename == '' {
		// We're moving a directory
		source_dir := self.get_dir_by_absolute_path(fs_id, normalized_source)!
		self.mv_directory(fs_id, source_dir.id, normalized_dest)!
	} else {
		// We're moving a specific item
		source_parent_dir := self.get_dir_by_absolute_path(fs_id, source_dir_path)!

		// Try to find what we're moving
		mut found := false

		// Try file first
		if file := self.get_file_by_path(source_parent_dir.id, source_filename) {
			self.mv_file(fs_id, file.id, normalized_dest, opts)!
			found = true
		}

		// Try symlink if file not found
		if !found {
			// Direct implementation since get_by_path doesn't exist for symlinks
			symlinks := self.factory.fs_symlink.list_by_parent(source_parent_dir.id)!
			for symlink in symlinks {
				if symlink.name == source_filename {
					self.mv_symlink(fs_id, symlink.id, normalized_dest, opts)!
					found = true
					break
				}
			}
		}

		// Try directory if neither file nor symlink found
		if !found {
			if subdir := self.find_child_dir_by_name(source_parent_dir.id, source_filename) {
				self.mv_directory(fs_id, subdir.id, normalized_dest)!
				found = true
			}
		}

		if !found {
			return error('Source path "${source_path}" not found')
		}
	}
}

// Move a file to destination path
fn (mut self FsTools) mv_file(fs_id u32, file_id u32, dest_path string, opts MoveOptions) ! {
	source_file := self.factory.fs_file.get(file_id)!

	// Determine destination directory and filename
	dest_dir_path, mut dest_filename := split_path(dest_path)
	if dest_filename == '' {
		dest_filename = source_file.name
	}

	// Ensure destination directory exists
	dest_dir_id := self.create_dir_path(fs_id, dest_dir_path)!

	// Check if destination file already exists
	if existing_file := self.get_file_by_path(dest_dir_id, dest_filename) {
		if !opts.overwrite {
			return error('Destination file "${dest_path}" already exists. Use overwrite=true to replace.')
		}
		// Remove existing file
		self.factory.fs_file.delete(existing_file.id)!
	}

	// Update file name if it's different
	// Direct implementation since rename doesn't exist for files
	if dest_filename != source_file.name {
		source_file.name = dest_filename
		self.factory.fs_file.set(source_file)!
	}

	// Move file to new directory (replace all directory associations)
	// Direct implementation since move doesn't exist for files
	source_file.directories = [dest_dir_id]
	self.factory.fs_file.set(source_file)!
}

// Move a symlink to destination path
fn (mut self FsTools) mv_symlink(fs_id u32, symlink_id u32, dest_path string, opts MoveOptions) ! {
	source_symlink := self.factory.fs_symlink.get(symlink_id)!

	if opts.follow_symlinks {
		// Follow the symlink and move its target instead
		if source_symlink.target_type == .file {
			self.mv_file(fs_id, source_symlink.target_id, dest_path, opts)!
		} else if source_symlink.target_type == .directory {
			self.mv_directory(fs_id, source_symlink.target_id, dest_path)!
		}
		// Remove the original symlink
		self.factory.fs_symlink.delete(symlink_id)!
		return
	}

	// Move the symlink itself
	dest_dir_path, mut dest_filename := split_path(dest_path)
	if dest_filename == '' {
		dest_filename = source_symlink.name
	}

	// Ensure destination directory exists
	dest_dir_id := self.create_dir_path(fs_id, dest_dir_path)!

	// Check if destination symlink already exists
	// Direct implementation since get_by_path doesn't exist for symlinks
	symlinks := self.factory.fs_symlink.list_by_parent(dest_dir_id)!
	for existing_symlink in symlinks {
		if existing_symlink.name == dest_filename {
			if !opts.overwrite {
				return error('Destination symlink "${dest_path}" already exists. Use overwrite=true to replace.')
			}
			self.factory.fs_symlink.delete(existing_symlink.id)!
			break
		}
	}

	// Update symlink name if it's different
	// Direct implementation since rename doesn't exist for symlinks
	if dest_filename != source_symlink.name {
		source_symlink.name = dest_filename
		self.factory.fs_symlink.set(source_symlink)!
	}

	// Move symlink to new parent directory
	// Direct implementation since move doesn't exist for symlinks
	source_symlink.parent_id = dest_dir_id
	self.factory.fs_symlink.set(source_symlink)!
}

// Move a directory to destination path
fn (mut self FsTools) mv_directory(fs_id u32, source_dir_id u32, dest_path string) ! {
	source_dir := self.factory.fs_dir.get(source_dir_id)!

	// Parse destination path
	dest_parent_path, mut dest_dirname := split_path(dest_path)
	if dest_dirname == '' {
		dest_dirname = source_dir.name
	}

	// Ensure destination parent directory exists
	dest_parent_id := if dest_parent_path == '/' {
		// Moving to root level, find root directory
		fs := self.factory.fs.get(fs_id)!
		fs.root_dir_id
	} else {
		self.create_dir_path(fs_id, dest_parent_path)!
	}

	// Update directory name if it's different
	// Direct implementation since rename doesn't exist for directories
	if dest_dirname != source_dir.name {
		source_dir.name = dest_dirname
		self.factory.fs_dir.set(source_dir)!
	}

	// Move directory to new parent
	// Direct implementation since move doesn't exist for directories
	source_dir.parent_id = dest_parent_id
	self.factory.fs_dir.set(source_dir)!
}
