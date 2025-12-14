//! File Operations
//!
//! File listing, reading, and tree building with ignore pattern support.
module heroprompt_backend

import incubaid.herolib.ai.filemap
import incubaid.herolib.core.pathlib

// FileInfo represents a file or directory in the tree.
pub struct FileInfo {
pub mut:
	path     string     // Relative path within directory
	name     string     // File/directory name
	is_dir   bool       // True if directory
	size     i64        // File size in bytes
	children []FileInfo // Children (for directories)
}

// FileContent represents file path and content.
pub struct FileContent {
pub mut:
	path    string
	content string
}

// SearchResult represents a search match.
pub struct SearchResult {
pub mut:
	path        string // File path
	line_number int    // Line number (1-based)
	line        string // Matching line
	context     string // Context around match
}

// ListFilesArgs specifies options for listing files.
@[params]
pub struct ListFilesArgs {
pub mut:
	workspace_id string @[required]
	dir_id       string // Filter to specific directory
}

// list_files returns file maps for workspace directories.
pub fn (self &HeropromptBackend) list_files(args ListFilesArgs) !map[string]filemap.FileMap {
	ws := self.get_workspace(id: args.workspace_id)!
	mut result := map[string]filemap.FileMap{}

	for dir in ws.dirs {
		if args.dir_id != '' && dir.id != args.dir_id {
			continue
		}
		result[dir.id] = filemap.filemap(path: dir.path, content_read: false)!
	}
	return result
}

// GetFileTreeArgs specifies options for building a file tree.
@[params]
pub struct GetFileTreeArgs {
pub mut:
	dir_path  string @[required]
	max_depth int = 10 // Maximum recursion depth
}

// get_file_tree returns the file tree structure for a directory.
pub fn get_file_tree(args GetFileTreeArgs) !FileInfo {
	mut dir := pathlib.get(args.dir_path)
	if !dir.exists() || !dir.is_dir() {
		return error('Directory does not exist: ${args.dir_path}')
	}

	ignore_patterns := filemap.find_ignore_patterns(args.dir_path)!
	return build_file_tree(mut dir, args.dir_path, ignore_patterns, 0, args.max_depth)!
}

// build_file_tree recursively builds the file tree with depth limiting.
fn build_file_tree(mut path pathlib.Path, base_path string, ignore_patterns []string, depth int, max_depth int) !FileInfo {
	mut info := FileInfo{
		path:   path.path_relative(base_path) or { path.path }
		name:   path.name()
		is_dir: path.is_dir()
	}

	if path.is_dir() {
		if depth >= max_depth {
			return info
		}

		mut file_list := path.list(
			recursive:     false
			filter_ignore: ignore_patterns
		)!

		for mut child in file_list.paths {
			info.children << build_file_tree(mut child, base_path, ignore_patterns, depth + 1, max_depth)!
		}
	} else {
		info.size = i64(path.size() or { 0 })
	}

	return info
}

// GetFileContentArgs specifies options for reading file content.
@[params]
pub struct GetFileContentArgs {
pub mut:
	path string @[required]
}

// get_file_content reads and returns file content.
pub fn get_file_content(args GetFileContentArgs) !string {
	mut file := pathlib.get(args.path)
	if !file.exists() {
		return error('File does not exist: ${args.path}')
	}
	if !file.is_file() {
		return error('Path is not a file: ${args.path}')
	}
	return file.read()!
}

// GetFilesContentArgs specifies options for reading multiple files.
@[params]
pub struct GetFilesContentArgs {
pub mut:
	paths []string @[required]
}

// get_files_content reads multiple files and returns their content.
pub fn get_files_content(args GetFilesContentArgs) ![]FileContent {
	mut result := []FileContent{}
	for path in args.paths {
		content := get_file_content(path: path) or { continue }
		result << FileContent{path: path, content: content}
	}
	return result
}
