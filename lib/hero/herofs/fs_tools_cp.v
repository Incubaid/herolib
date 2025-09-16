module herofs

// CopyOptions provides options for copy operations
@[params]
pub struct CopyOptions {
pub mut:
	recursive  bool = true // Copy directories recursively
	overwrite  bool // Overwrite existing files at destination
	copy_blobs bool = true // Create new blob copies (true) or reference same blobs (false)
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
	// Try to find items using the find function first
	mut items := []FindResult{}

	// If find fails, try to get the item directly by path
	items = self.find(src_path, find_opts) or {
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

	// Determine destination directory
	mut dest_dir_id := u32(0)

	// Check if destination is an existing directory
	if dest_dir := self.get_dir_by_absolute_path(dest_path) {
		dest_dir_id = dest_dir.id
	} else {
		// If destination doesn't exist as directory, treat it as a directory path to create
		// or as a parent directory if it looks like a file path
		mut dir_to_create := dest_path
		if !dest_path.ends_with('/') && items.len == 1 && items[0].result_type == .file {
			// Single file copy to a specific filename - use parent directory
			path_parts := dest_path.trim_left('/').split('/')
			if path_parts.len > 1 {
				dir_to_create = '/' + path_parts[..path_parts.len - 1].join('/')
			} else {
				dir_to_create = '/'
			}
		}

		// Create the destination directory if it doesn't exist
		if dir_to_create != '/' {
			self.factory.fs_dir.create_path(self.id, dir_to_create)!
		}
		dest_dir_id = self.get_dir_by_absolute_path(dir_to_create)!.id
	}

	// Copy each found item
	for item in items {
		match item.result_type {
			.file {
				self.copy_file(item.id, dest_dir_id, copy_opts)!
			}
			.directory {
				if copy_opts.recursive {
					self.copy_directory(item.id, dest_dir_id, copy_opts)!
				}
			}
			.symlink {
				self.copy_symlink(item.id, dest_dir_id, copy_opts)!
			}
		}
	}
}

// copy_file copies a single file to a destination directory
fn (mut self Fs) copy_file(file_id u32, dest_dir_id u32, opts CopyOptions) ! {
	original_file := self.factory.fs_file.get(file_id)!
	dest_dir := self.factory.fs_dir.get(dest_dir_id)!

	// Check if file already exists in destination
	for existing_file_id in dest_dir.files {
		existing_file := self.factory.fs_file.get(existing_file_id)!
		if existing_file.name == original_file.name {
			if !opts.overwrite {
				return error('File "${original_file.name}" already exists in destination directory')
			}
			// Remove existing file
			self.factory.fs_file.delete(existing_file_id)!
			break
		}
	}

	// Create new blobs or reference existing ones
	mut new_blob_ids := []u32{}
	if opts.copy_blobs {
		// Create new blob copies
		for blob_id in original_file.blobs {
			original_blob := self.factory.fs_blob.get(blob_id)!
			mut new_blob := self.factory.fs_blob.new(data: original_blob.data)!
			self.factory.fs_blob.set(mut new_blob)!
			new_blob_ids << new_blob.id
		}
	} else {
		// Reference the same blobs
		new_blob_ids = original_file.blobs.clone()
	}

	// Create new file
	mut new_file := self.factory.fs_file.new(
		name:      original_file.name
		fs_id:     self.id
		blobs:     new_blob_ids
		mime_type: original_file.mime_type
		metadata:  original_file.metadata.clone()
	)!

	self.factory.fs_file.set(mut new_file)!
	self.factory.fs_file.add_to_directory(new_file.id, dest_dir_id)!
}

// copy_directory copies a directory and optionally its contents recursively
fn (mut self Fs) copy_directory(dir_id u32, dest_parent_id u32, opts CopyOptions) ! {
	original_dir := self.factory.fs_dir.get(dir_id)!
	dest_parent := self.factory.fs_dir.get(dest_parent_id)!

	// Check if directory already exists in destination
	for existing_dir_id in dest_parent.directories {
		existing_dir := self.factory.fs_dir.get(existing_dir_id)!
		if existing_dir.name == original_dir.name {
			if !opts.overwrite {
				return error('Directory "${original_dir.name}" already exists in destination')
			}
			// For directories, we merge rather than replace when overwrite is true
			if opts.recursive {
				// Copy contents into existing directory
				self.copy_directory_contents(dir_id, existing_dir_id, opts)!
			}
			return
		}
	}

	// Create new directory
	mut new_dir := self.factory.fs_dir.new(
		name:        original_dir.name
		fs_id:       self.id
		parent_id:   dest_parent_id
		description: original_dir.description
	)!

	self.factory.fs_dir.set(mut new_dir)!

	// Add to parent's directories list
	mut parent := self.factory.fs_dir.get(dest_parent_id)!
	parent.directories << new_dir.id
	self.factory.fs_dir.set(mut parent)!

	// Copy contents if recursive
	if opts.recursive {
		self.copy_directory_contents(dir_id, new_dir.id, opts)!
	}
}

// copy_directory_contents copies all contents of a directory to another directory
fn (mut self Fs) copy_directory_contents(src_dir_id u32, dest_dir_id u32, opts CopyOptions) ! {
	src_dir := self.factory.fs_dir.get(src_dir_id)!

	// Copy all files
	for file_id in src_dir.files {
		self.copy_file(file_id, dest_dir_id, opts)!
	}

	// Copy all symlinks
	for symlink_id in src_dir.symlinks {
		self.copy_symlink(symlink_id, dest_dir_id, opts)!
	}

	// Copy all subdirectories recursively
	for subdir_id in src_dir.directories {
		self.copy_directory(subdir_id, dest_dir_id, opts)!
	}
}

// copy_symlink copies a symbolic link to a destination directory
fn (mut self Fs) copy_symlink(symlink_id u32, dest_dir_id u32, opts CopyOptions) ! {
	original_symlink := self.factory.fs_symlink.get(symlink_id)!
	dest_dir := self.factory.fs_dir.get(dest_dir_id)!

	// Check if symlink already exists in destination
	for existing_symlink_id in dest_dir.symlinks {
		existing_symlink := self.factory.fs_symlink.get(existing_symlink_id)!
		if existing_symlink.name == original_symlink.name {
			if !opts.overwrite {
				return error('Symlink "${original_symlink.name}" already exists in destination directory')
			}
			// Remove existing symlink
			self.factory.fs_symlink.delete(existing_symlink_id)!
			break
		}
	}

	// Create new symlink
	mut new_symlink := self.factory.fs_symlink.new(
		name:        original_symlink.name
		fs_id:       self.id
		parent_id:   dest_dir_id
		target_id:   original_symlink.target_id
		target_type: original_symlink.target_type
		description: original_symlink.description
	)!

	self.factory.fs_symlink.set(mut new_symlink)!

	// Add to parent directory's symlinks list
	mut parent := self.factory.fs_dir.get(dest_dir_id)!
	parent.symlinks << new_symlink.id
	self.factory.fs_dir.set(mut parent)!
}
