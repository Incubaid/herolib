module herofs

// MoveOptions provides options for move operations
@[params]
pub struct MoveOptions {
pub mut:
	overwrite bool // Overwrite existing files at destination
}

// mv moves files and directories from source path to destination
//
// Parameters:
// - src_path: Source path (exact path, not pattern)
// - dest_path: Destination path
// - opts: MoveOptions for move behavior
//
// Example:
// ```
// fs.mv('/src/main.v', '/backup/main.v', MoveOptions{overwrite: true})!
// ```
pub fn (mut self Fs) mv(src_path string, dest_path string, opts MoveOptions) ! {
	// Determine what type of item we're moving
	mut src_item_type := FSItemType.file
	mut src_item_id := u32(0)
	mut src_name := ''

	// Try to find the source item (try file first, then directory, then symlink)
	if src_file := self.get_file_by_absolute_path(src_path) {
		src_item_type = .file
		src_item_id = src_file.id
		src_name = src_file.name
	} else if src_dir := self.get_dir_by_absolute_path(src_path) {
		src_item_type = .directory
		src_item_id = src_dir.id
		src_name = src_dir.name
	} else if src_symlink := self.get_symlink_by_absolute_path(src_path) {
		src_item_type = .symlink
		src_item_id = src_symlink.id
		src_name = src_symlink.name
	} else {
		return error('Source path "${src_path}" not found')
	}

	// Parse destination path
	dest_path_parts := dest_path.trim_left('/').split('/')
	if dest_path_parts.len == 0 {
		return error('Invalid destination path: "${dest_path}"')
	}

	// Determine destination directory and new name
	mut dest_dir_path := ''
	mut new_name := ''

	if dest_path.ends_with('/') {
		// Moving into a directory with same name
		dest_dir_path = dest_path.trim_right('/')
		new_name = src_name
	} else {
		// Check if destination exists as directory
		if _ := self.get_dir_by_absolute_path(dest_path) {
			// Destination is an existing directory
			dest_dir_path = dest_path
			new_name = src_name
		} else {
			// Destination doesn't exist as directory, treat as rename
			if dest_path_parts.len == 1 {
				dest_dir_path = '/'
				new_name = dest_path_parts[0]
			} else {
				dest_dir_path = '/' + dest_path_parts[..dest_path_parts.len - 1].join('/')
				new_name = dest_path_parts[dest_path_parts.len - 1]
			}
		}
	}

	// Get destination directory
	dest_dir := self.get_dir_by_absolute_path(dest_dir_path) or {
		return error('Destination directory "${dest_dir_path}" not found')
	}

	// Perform the move based on item type
	match src_item_type {
		.file {
			self.move_file(src_item_id, dest_dir.id, new_name, opts)!
		}
		.directory {
			self.move_directory(src_item_id, dest_dir.id, new_name, opts)!
		}
		.symlink {
			self.move_symlink(src_item_id, dest_dir.id, new_name, opts)!
		}
	}
}

// move_file moves a file to a new directory and optionally renames it
fn (mut self Fs) move_file(file_id u32, dest_dir_id u32, new_name string, opts MoveOptions) ! {
	mut file := self.factory.fs_file.get(file_id)!
	dest_dir := self.factory.fs_dir.get(dest_dir_id)!

	// Check if file with same name already exists in destination
	for existing_file_id in dest_dir.files {
		existing_file := self.factory.fs_file.get(existing_file_id)!
		if existing_file.name == new_name {
			if !opts.overwrite {
				return error('File "${new_name}" already exists in destination directory')
			}
			// Remove existing file
			self.factory.fs_file.delete(existing_file_id)!
			break
		}
	}

	// Remove file from all current directories
	current_dirs := self.factory.fs_file.list_directories_for_file(file_id)!
	for dir_id in current_dirs {
		mut dir := self.factory.fs_dir.get(dir_id)!
		dir.files = dir.files.filter(it != file_id)
		self.factory.fs_dir.set(mut dir)!
	}

	// Update file name if needed
	if file.name != new_name {
		file.name = new_name
		self.factory.fs_file.set(mut file)!
	}

	// Add file to destination directory
	self.factory.fs_file.add_to_directory(file_id, dest_dir_id)!
}

// move_directory moves a directory to a new parent and optionally renames it
fn (mut self Fs) move_directory(dir_id u32, dest_parent_id u32, new_name string, opts MoveOptions) ! {
	mut dir := self.factory.fs_dir.get(dir_id)!
	dest_parent := self.factory.fs_dir.get(dest_parent_id)!

	// Check if directory with same name already exists in destination
	for existing_dir_id in dest_parent.directories {
		existing_dir := self.factory.fs_dir.get(existing_dir_id)!
		if existing_dir.name == new_name {
			if !opts.overwrite {
				return error('Directory "${new_name}" already exists in destination')
			}
			// Directory merging is not supported - would require complex conflict resolution
			return error('Cannot overwrite existing directory "${new_name}" - directory merging not supported')
		}
	}

	// Remove from old parent's directories list
	if dir.parent_id > 0 {
		mut old_parent := self.factory.fs_dir.get(dir.parent_id)!
		old_parent.directories = old_parent.directories.filter(it != dir_id)
		self.factory.fs_dir.set(mut old_parent)!
	}

	// Update directory name and parent
	if dir.name != new_name {
		dir.name = new_name
	}
	dir.parent_id = dest_parent_id
	self.factory.fs_dir.set(mut dir)!

	// Add to new parent's directories list
	mut new_parent := self.factory.fs_dir.get(dest_parent_id)!
	if dir_id !in new_parent.directories {
		new_parent.directories << dir_id
	}
	self.factory.fs_dir.set(mut new_parent)!
}

// move_symlink moves a symlink to a new directory and optionally renames it
fn (mut self Fs) move_symlink(symlink_id u32, dest_dir_id u32, new_name string, opts MoveOptions) ! {
	mut symlink := self.factory.fs_symlink.get(symlink_id)!
	dest_dir := self.factory.fs_dir.get(dest_dir_id)!

	// Check if symlink with same name already exists in destination
	for existing_symlink_id in dest_dir.symlinks {
		existing_symlink := self.factory.fs_symlink.get(existing_symlink_id)!
		if existing_symlink.name == new_name {
			if !opts.overwrite {
				return error('Symlink "${new_name}" already exists in destination directory')
			}
			// Remove existing symlink
			self.factory.fs_symlink.delete(existing_symlink_id)!
			break
		}
	}

	// Remove from old parent's symlinks list
	if symlink.parent_id > 0 {
		mut old_parent := self.factory.fs_dir.get(symlink.parent_id)!
		old_parent.symlinks = old_parent.symlinks.filter(it != symlink_id)
		self.factory.fs_dir.set(mut old_parent)!
	}

	// Update symlink name and parent
	if symlink.name != new_name {
		symlink.name = new_name
	}
	symlink.parent_id = dest_dir_id
	self.factory.fs_symlink.set(mut symlink)!

	// Add to new parent's symlinks list
	mut new_parent := self.factory.fs_dir.get(dest_dir_id)!
	if symlink_id !in new_parent.symlinks {
		new_parent.symlinks << symlink_id
	}
	self.factory.fs_dir.set(mut new_parent)!
}
