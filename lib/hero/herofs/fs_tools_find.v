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
pub fn (mut self Fs) find(start_path string, opts FindOptions) ![]FindResult {
	mut results := []FindResult{}

	// Try to get the path as a file first
	if file := self.get_file_by_absolute_path(start_path) {
		// Path points to a specific file
		if should_include(file.name, opts.include_patterns, opts.exclude_patterns) {
			results << FindResult{
				result_type: .file
				id:          file.id
				path:        start_path
			}
		}
		return results
	} else {
		// Try to get the path as a symlink
		if symlink := self.get_symlink_by_absolute_path(start_path) {
			// Path points to a specific symlink
			if should_include(symlink.name, opts.include_patterns, opts.exclude_patterns) {
				results << FindResult{
					result_type: .symlink
					id:          symlink.id
					path:        start_path
				}
			}
			return results
		} else {
			// Path should be a directory - proceed with recursive search
			start_dir := self.get_dir_by_absolute_path(start_path)!
			self.find_recursive(start_dir.id, start_path, opts, mut results, 0)!
			return results
		}
	}
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
fn (mut self Fs) find_recursive(dir_id u32, current_path string, opts FindOptions, mut results []FindResult, current_depth int) ! {
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
			// only add symlink if not following them
			if !opts.follow_symlinks {
				results << FindResult{
					result_type: .symlink
					id:          symlink.id
					path:        symlink_path
				}
			} else {
				if symlink.target_type == .file {
					if self.factory.fs_file.exist(symlink.target_id)! {
						target_file := self.factory.fs_file.get(symlink.target_id)!
						target_file_path := join_path(current_path, target_file.name)
						// Check if we've already added this file to avoid duplicates
						mut found := false
						for result in results {
							if result.id == target_file.id && result.result_type == .file {
								found = true
								break
							}
						}
						if !found {
							results << FindResult{
								result_type: .file
								id:          target_file.id
								path:        target_file_path
							}
						}
					} else {
						// dangling symlink, just add the symlink itself
						return error('Dangling symlink at path ${symlink_path} in directory ${current_path} in fs: ${self.id}')
					}
				}

				if symlink.target_type == .directory {
					if self.factory.fs_dir.exist(symlink.target_id)! {
						target_dir := self.factory.fs_dir.get(symlink.target_id)!
						target_dir_path := join_path(current_path, target_dir.name)
						// Check if we've already added this directory to avoid duplicates
						mut found := false
						for result in results {
							if result.id == target_dir.id && result.result_type == .directory {
								found = true
								break
							}
						}
						if !found {
							results << FindResult{
								result_type: .directory
								id:          target_dir.id
								path:        target_dir_path
							}
							if opts.recursive {
								self.find_recursive(symlink.target_id, target_dir_path,
									opts, mut results, current_depth + 1)!
							}
						}
					} else {
						// dangling symlink, just add the symlink itself
						return error('Dangling dir symlink at path ${symlink_path} in directory ${current_path} in fs: ${self.id}')
					}
				}
			}
		}
	}

	for dir_id2 in current_dir.directories {
		subdir := self.factory.fs_dir.get(dir_id2)!
		subdir_path := join_path(current_path, subdir.name)

		// Include child directories in results if they match patterns
		if should_include(subdir.name, opts.include_patterns, opts.exclude_patterns) {
			if !opts.recursive {
				results << FindResult{
					result_type: .directory
					id:          subdir.id
					path:        subdir_path
				}
			}
		}

		// Always recurse into directories when recursive is true, regardless of patterns
		// The patterns apply to what gets included in results, not to traversal
		if opts.recursive {
			self.find_recursive(dir_id2, subdir_path, opts, mut results, current_depth + 1)!
		}
	}
}

// get_dir_by_absolute_path resolves an absolute path to a directory ID
//
// Parameters:
// - path: The absolute path to resolve (e.g., "/", "/home", "/home/user/documents")
//
// Returns:
// - FsDir: The directory object at the specified path
//
// Example:
// ```
// dir := tools.get_dir_by_absolute_path('/home/user/documents')!
// ```
pub fn (mut self Fs) get_dir_by_absolute_path(path string) !FsDir {
	normalized_path_ := normalize_path(path)

	// Handle root directory case
	if normalized_path_ == '/' {
		fs := self.factory.fs.get(self.id)!
		return self.factory.fs_dir.get(fs.root_dir_id)!
	}

	// Split path into components, removing empty parts
	path_components := normalized_path_.trim_left('/').split('/').filter(it != '')

	// Start from root directory
	fs := self.factory.fs.get(self.id)!
	mut current_dir_id := fs.root_dir_id

	// Navigate through each path component
	for component in path_components {
		current_dir := self.factory.fs_dir.get(current_dir_id)!

		// Look for the component in the current directory's children
		mut found := false
		for child_dir_id in current_dir.directories {
			child_dir := self.factory.fs_dir.get(child_dir_id)!
			if child_dir.name == component {
				current_dir_id = child_dir_id
				found = true
				break
			}
		}

		if !found {
			return error('Directory "${component}" not found in path "${path}"')
		}
	}

	return self.factory.fs_dir.get(current_dir_id)!
}

// get_file_by_absolute_path resolves an absolute path to a file
//
// Parameters:
// - path: The absolute path to resolve (e.g., "/home/user/document.txt")
//
// Returns:
// - FsFile: The file object at the specified path
//
// Example:
// ```
// file := tools.get_file_by_absolute_path('/home/user/document.txt')!
// ```
pub fn (mut self Fs) get_file_by_absolute_path(path string) !FsFile {
	normalized_path := normalize_path(path)

	// Split path into directory and filename
	path_parts := normalized_path.trim_left('/').split('/')
	if path_parts.len == 0 || path_parts[path_parts.len - 1] == '' {
		return error('Invalid file path: "${path}"')
	}

	filename := path_parts[path_parts.len - 1]
	dir_path := if path_parts.len == 1 {
		'/'
	} else {
		'/' + path_parts[..path_parts.len - 1].join('/')
	}

	// Get the directory
	dir := self.get_dir_by_absolute_path(dir_path)!

	// Find the file in the directory
	for file_id in dir.files {
		file := self.factory.fs_file.get(file_id)!
		if file.name == filename {
			return file
		}
	}

	return error('File "${filename}" not found in directory "${dir_path}"')
}

// get_symlink_by_absolute_path resolves an absolute path to a symlink
//
// Parameters:
// - path: The absolute path to resolve (e.g., "/home/user/link.txt")
//
// Returns:
// - FsSymlink: The symlink object at the specified path
//
// Example:
// ```
// symlink := tools.get_symlink_by_absolute_path('/home/user/link.txt')!
// ```
pub fn (mut self Fs) get_symlink_by_absolute_path(path string) !FsSymlink {
	normalized_path := normalize_path(path)

	// Split path into directory and symlink name
	path_parts := normalized_path.trim_left('/').split('/')
	if path_parts.len == 0 || path_parts[path_parts.len - 1] == '' {
		return error('Invalid symlink path: "${path}"')
	}

	symlink_name := path_parts[path_parts.len - 1]
	dir_path := if path_parts.len == 1 {
		'/'
	} else {
		'/' + path_parts[..path_parts.len - 1].join('/')
	}

	// Get the directory
	dir := self.get_dir_by_absolute_path(dir_path)!

	// Find the symlink in the directory
	for symlink_id in dir.symlinks {
		symlink := self.factory.fs_symlink.get(symlink_id)!
		if symlink.name == symlink_name {
			return symlink
		}
	}

	return error('Symlink "${symlink_name}" not found in directory "${dir_path}"')
}
