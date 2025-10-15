module herofs

// get_abs_path_for_item returns the absolute path for a given filesystem item ID and type
pub fn (mut self Fs) get_abs_path_for_item(id u32, item_type FSItemType) !string {
	match item_type {
		.file {
			// Find the directory containing the file
			// This is inefficient and should be optimized in a real implementation
			all_dirs := self.factory.fs_dir.list()!
			for dir in all_dirs {
				if id in dir.files {
					parent_path := self.get_abs_path_for_item(dir.id, .directory)!
					file := self.factory.fs_file.get(id)!
					return join_path(parent_path, file.name)
				}
			}
			return error('File with ID ${id} not found in any directory')
		}
		.directory {
			mut path_parts := []string{}
			mut current_dir_id := id
			for {
				dir := self.factory.fs_dir.get(current_dir_id)!
				path_parts.insert(0, dir.name)
				if dir.parent_id == 0 {
					break
				}
				current_dir_id = dir.parent_id
			}
			// Don't prepend slash to root, which is just 'root'
			if path_parts.len > 0 && path_parts[0] == 'root' {
				path_parts.delete(0)
			}
			return '/' + path_parts.join('/')
		}
		.symlink {
			// Similar to file logic, find parent directory
			all_dirs := self.factory.fs_dir.list()!
			for dir in all_dirs {
				if id in dir.symlinks {
					parent_path := self.get_abs_path_for_item(dir.id, .directory)!
					symlink := self.factory.fs_symlink.get(id)!
					return join_path(parent_path, symlink.name)
				}
			}
			return error('Symlink with ID ${id} not found in any directory')
		}
	}
	return '' // Should be unreachable
}
