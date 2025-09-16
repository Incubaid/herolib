module herofs

// RemoveOptions provides options for remove operations
@[params]
pub struct RemoveOptions {
pub mut:
	recursive    bool // Remove directories recursively
	delete_blobs bool // Delete associated blobs (true) or keep them (false)
	force        bool // Force removal even if directory is not empty
}

// rm removes files and directories matching the given path pattern
//
// Parameters:
// - path: Path pattern to match for removal
// - find_opts: FindOptions for filtering items to remove
// - remove_opts: RemoveOptions for removal behavior
//
// Example:
// ```
// fs.rm('/temp/*', FindOptions{recursive: true}, RemoveOptions{recursive: true, delete_blobs: true})!
// ```
pub fn (mut self Fs) rm(path string, find_opts FindOptions, remove_opts RemoveOptions) ! {
	// Find all items matching the pattern
	items := self.find(path, find_opts)!

	if items.len == 0 {
		return error('No items found matching pattern: ${path}')
	}

	// Sort items by type and depth to ensure proper removal order
	// (files first, then symlinks, then directories from deepest to shallowest)
	mut files := []FindResult{}
	mut symlinks := []FindResult{}
	mut directories := []FindResult{}

	for item in items {
		match item.result_type {
			.file { files << item }
			.symlink { symlinks << item }
			.directory { directories << item }
		}
	}

	// Sort directories by depth (deepest first)
	directories.sort_with_compare(fn (a &FindResult, b &FindResult) int {
		depth_a := a.path.count('/')
		depth_b := b.path.count('/')
		return depth_b - depth_a // Reverse order (deepest first)
	})

	// Remove files first
	for file in files {
		self.remove_file(file.id, remove_opts)!
	}

	// Remove symlinks
	for symlink in symlinks {
		self.remove_symlink(symlink.id)!
	}

	// Remove directories (deepest first)
	for directory in directories {
		self.remove_directory(directory.id, remove_opts)!
	}
}

// remove_file removes a single file and optionally its blobs
fn (mut self Fs) remove_file(file_id u32, opts RemoveOptions) ! {
	file := self.factory.fs_file.get(file_id)!

	// Optionally delete associated blobs
	if opts.delete_blobs {
		for blob_id in file.blobs {
			// Check if blob is used by other files before deleting
			all_files := self.factory.fs_file.list()!
			mut blob_in_use := false
			for other_file in all_files {
				if other_file.id != file_id && blob_id in other_file.blobs {
					blob_in_use = true
					break
				}
			}

			// Only delete blob if not used by other files
			if !blob_in_use {
				self.factory.fs_blob.delete(blob_id)!
			}
		}
	}

	// Remove file from all directories
	containing_dirs := self.factory.fs_file.list_directories_for_file(file_id)!
	for dir_id in containing_dirs {
		mut dir := self.factory.fs_dir.get(dir_id)!
		dir.files = dir.files.filter(it != file_id)
		self.factory.fs_dir.set(mut dir)!
	}

	// Delete the file
	self.factory.fs_file.delete(file_id)!
}

// remove_symlink removes a single symlink
fn (mut self Fs) remove_symlink(symlink_id u32) ! {
	symlink := self.factory.fs_symlink.get(symlink_id)!

	// Remove from parent directory's symlinks list
	if symlink.parent_id > 0 {
		mut parent_dir := self.factory.fs_dir.get(symlink.parent_id)!
		parent_dir.symlinks = parent_dir.symlinks.filter(it != symlink_id)
		self.factory.fs_dir.set(mut parent_dir)!
	}

	// Delete the symlink
	self.factory.fs_symlink.delete(symlink_id)!
}

// remove_directory removes a directory and optionally its contents
fn (mut self Fs) remove_directory(dir_id u32, opts RemoveOptions) ! {
	dir := self.factory.fs_dir.get(dir_id)!

	// Check if directory is empty or if force/recursive removal is allowed
	has_contents := dir.files.len > 0 || dir.directories.len > 0 || dir.symlinks.len > 0

	if has_contents && !opts.recursive && !opts.force {
		return error('Directory "${dir.name}" is not empty. Use recursive option to remove contents.')
	}

	// Remove contents if recursive
	if opts.recursive && has_contents {
		// Remove all files
		for file_id in dir.files.clone() {
			self.remove_file(file_id, opts)!
		}

		// Remove all symlinks
		for symlink_id in dir.symlinks.clone() {
			self.remove_symlink(symlink_id)!
		}

		// Remove all subdirectories
		for subdir_id in dir.directories.clone() {
			self.remove_directory(subdir_id, opts)!
		}
	}

	// Remove from parent directory's directories list
	if dir.parent_id > 0 {
		mut parent_dir := self.factory.fs_dir.get(dir.parent_id)!
		parent_dir.directories = parent_dir.directories.filter(it != dir_id)
		self.factory.fs_dir.set(mut parent_dir)!
	}

	// Delete the directory
	self.factory.fs_dir.delete(dir_id)!
}
