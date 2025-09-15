module herofs

// FindResult represents the result of a filesystem search
pub struct FindResult {
pub mut:
	result_type FSItemType
	id          u32
	path        string
}

// FSItemType indicates what type of filesystem object was found
pub enum FSItemType {
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

// find searches for filesystem objects starting from a given path
// 
// Parameters:
// - start_path: The path to start searching from
// - opts: FindOptions struct with search parameters
// 
// Returns:
// - []FindResult: Array of found filesystem objects
// 
// Example:
// ```
// results := tools.find('/', FindOptions{
//     recursive: true
//     include_patterns: ['*.v']
//     exclude_patterns: ['*test*']
// })!
// ```
pub fn (mut self FsTools) find(start_path string, opts FindOptions) ![]FindResult {
	mut results := []FindResult{}

	// Get the starting directory
	start_dir := self.get_dir_by_absolute_path(start_path)!

	// Start recursive search
	self.find_recursive(start_dir.id, start_path, opts, mut results, 0)!

	return results
}

// find_recursive is an internal function that recursively searches for filesystem objects
// 
// Parameters:
// - dir_id: The ID of the current directory being searched
// - current_path: The current path in the filesystem
// - opts: FindOptions struct with search parameters
// - results: Mutable array to store found filesystem objects
// - current_depth: Current depth in the directory tree
// 
// This function handles three types of filesystem objects:
// - Files: Direct files in the current directory
// - Symlinks: Symbolic links in the current directory (handled according to opts.follow_symlinks)
// - Directories: Subdirectories of the current directory (recursed into according to opts.recursive)
fn (mut self FsTools) find_recursive(dir_id u32, current_path string, opts FindOptions, mut results []FindResult, current_depth int) ! {
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
		}
	}

	// Get files in current directory
	for file_id in current_dir.files {
		file := self.factory.fs_file.get(file_id)!
		if should_include(file.name, opts.include_patterns, opts.exclude_patterns) {
			file_path := join_path(current_path, file.name)
			results << FindResult{
				result_type: .file
				id:          file.id
				path:        file_path
			}
		}
	}


	// Get symlinks in current directory

	for symlink_id in current_dir.symlinks {
		symlink := self.factory.fs_symlink.get(symlink_id)!
		if should_include(symlink.name, opts.include_patterns, opts.exclude_patterns) {
			symlink_path := join_path(current_path, symlink.name)
			//only add symlink if not following them
			if !opts.follow_symlinks {
				results << FindResult{
					result_type: .symlink
					id:          symlink.id
					path:        symlink_path
				}
			}else{
				if symlink.target_type == .file {
					if self.factory.fs_file.exist(symlink.target_id)! {
						target_file := self.factory.fs_file.get(symlink.target_id)!
						target_file_path := join_path(current_path, target_file.name)
						results << FindResult{
							result_type: .file
							id:          target_file.id
							path:        target_file_path
						}
					}else{
						//dangling symlink, just add the symlink itself
						return error('Dangling symlink at path ${symlink_path} in directory ${current_path} in fs: ${self.fs_id}')
					}
				}

				if symlink.target_type == .directory {
					if self.factory.fs_dir.exist(symlink.target_id)! {
						target_dir := self.factory.fs_dir.get(symlink.target_id)!
						target_dir_path := join_path(current_path, target_dir.name)
						results << FindResult{
							result_type: .directory
							id:          target_dir.id
							path:        target_dir_path
						}
						if opts.recursive {
							self.find_recursive(symlink.target_id, target_dir_path, opts, mut results, current_depth + 1)!
						}
					}else{
						//dangling symlink, just add the symlink itself
						return error('Dangling dir symlink at path ${symlink_path} in directory ${current_path} in fs: ${self.fs_id}')
					}
				}
			}
		}

	}

	for dir_id in current_dir.directories {
		subdir := self.factory.fs_dir.get(dir_id)!
		if should_include(subdir.name, opts.include_patterns, opts.exclude_patterns) {
			subdir_path := join_path(current_path, subdir.name)
			results << FindResult{
				result_type: .directory
				id:          subdir.id
				path:        subdir_path
			}

			// Process subdirectories if recursive
			if opts.recursive {
				self.find_recursive(dir_id, subdir_path, opts, mut results, current_depth + 1)!
			}
		}
	}

}
