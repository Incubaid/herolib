module heroprompt

import os
import rand
import incubaid.herolib.core.pathlib
import incubaid.herolib.develop.codewalker
import incubaid.herolib.data.ourtime

// Directory represents a directory/directory added to a workspace
// It contains metadata about the directory and its location
@[heap]
pub struct Directory {
pub mut:
	id             string = rand.uuid_v4() // Unique identifier for this directory
	name           string          // Display name (can be customized by user)
	path           string          // Absolute path to the directory
	description    string          // Optional description
	git_info       GitInfo         // Git directory information (if applicable)
	created        ourtime.OurTime // When this directory was added
	updated        ourtime.OurTime // Last update time
	include_tree   bool = true // Whether to include full tree in file maps
	is_expanded    bool            // UI state: whether directory is expanded in tree view
	is_selected    bool            // UI state: whether directory checkbox is checked
	selected_files map[string]bool // Map of file paths to selection state (normalized paths)
}

// GitInfo contains git-specific metadata for a directory
pub struct GitInfo {
pub mut:
	is_git_dir     bool   // Whether this is a git directory
	current_branch string // Current git branch
	remote_url     string // Remote URL (if any)
	last_commit    string // Last commit hash
	has_changes    bool   // Whether there are uncommitted changes
}

// Create a new directory from a directory path
@[params]
pub struct NewDirectoryParams {
pub mut:
	path        string @[required] // Absolute path to directory
	name        string // Optional custom name (defaults to directory name)
	description string // Optional description
}

// Create a new directory instance
pub fn new_directory(args NewDirectoryParams) !Directory {
	if args.path.len == 0 {
		return error('directory path is required')
	}

	mut dir_path := pathlib.get(args.path)
	if !dir_path.exists() || !dir_path.is_dir() {
		return error('path is not an existing directory: ${args.path}')
	}

	abs_path := dir_path.realpath()
	dir_name := dir_path.name()

	// Detect git information
	git_info := detect_git_info(abs_path)

	return Directory{
		id:           rand.uuid_v4()
		name:         if args.name.len > 0 { args.name } else { dir_name }
		path:         abs_path
		description:  args.description
		git_info:     git_info
		created:      ourtime.now()
		updated:      ourtime.now()
		include_tree: true
	}
}

// Detect git information for a directory
fn detect_git_info(path string) GitInfo {
	// TODO: Use the gittools library to get this information
	// Keep it for now, maybe next version
	mut info := GitInfo{
		is_git_dir: false
	}

	// Check if .git directory exists
	git_dir := os.join_path(path, '.git')
	if !os.exists(git_dir) {
		return info
	}

	info.is_git_dir = true

	// Try to detect current branch
	head_file := os.join_path(git_dir, 'HEAD')
	if os.exists(head_file) {
		head_content := os.read_file(head_file) or { '' }
		if head_content.contains('ref: refs/heads/') {
			info.current_branch = head_content.replace('ref: refs/heads/', '').trim_space()
		}
	}

	// Try to detect remote URL
	config_file := os.join_path(git_dir, 'config')
	if os.exists(config_file) {
		config_content := os.read_file(config_file) or { '' }
		// Simple parsing - look for url = line
		for line in config_content.split_into_lines() {
			trimmed := line.trim_space()
			if trimmed.starts_with('url = ') {
				info.remote_url = trimmed.replace('url = ', '')
				break
			}
		}
	}

	// Check for uncommitted changes (simplified - just check if there are any files in git status)
	// In a real implementation, would run `git status --porcelain`
	info.has_changes = false // Placeholder - would need to execute git command

	return info
}

// Update directory metadata
@[params]
pub struct UpdateDirectoryParams {
pub mut:
	name        string
	description string
}

pub fn (mut dir Directory) update(args UpdateDirectoryParams) {
	if args.name.len > 0 {
		dir.name = args.name
	}
	if args.description.len > 0 {
		dir.description = args.description
	}
	dir.updated = ourtime.now()
}

// Refresh git information for this directory
pub fn (mut dir Directory) refresh_git_info() {
	dir.git_info = detect_git_info(dir.path)
	dir.updated = ourtime.now()
}

// Check if directory path still exists
pub fn (dir &Directory) exists() bool {
	return os.exists(dir.path) && os.is_dir(dir.path)
}

// Get directory size (number of files)
pub fn (dir &Directory) file_count() !int {
	if !dir.exists() {
		return error('directory path no longer exists')
	}

	// Use codewalker to count files
	mut cw := codewalker.new(codewalker.CodeWalkerArgs{})!
	mut fm := cw.filemap_get(path: dir.path, content_read: false)!
	return fm.content.len
}

// Get display name with git branch if available
pub fn (dir &Directory) display_name() string {
	if dir.git_info.is_git_dir && dir.git_info.current_branch.len > 0 {
		return '${dir.name} (${dir.git_info.current_branch})'
	}
	return dir.name
}

// Directory Management Methods

// DirectoryContent holds the scanned files and directories from a directory
pub struct DirectoryContent {
pub mut:
	files       []HeropromptFile // All files found in the directory
	directories []string         // All directories found in the directory
	file_count  int              // Total number of files
	dir_count   int              // Total number of directories
}

// get_contents scans the directory and returns all files and directories
// This method respects .gitignore and .heroignore files
// This is a public method that can be used to retrieve directory contents for prompt generation
pub fn (dir &Directory) get_contents() !DirectoryContent {
	return dir.scan()
}

// scan scans the entire directory and returns all files and directories
// This method respects .gitignore and .heroignore files
// Note: This is a private method. Use add_dir() with scan parameter or get_contents() instead.
fn (dir &Directory) scan() !DirectoryContent {
	if !dir.exists() {
		return error('directory path does not exist: ${dir.path}')
	}

	// Use codewalker to scan the directory with gitignore support
	mut cw := codewalker.new(codewalker.CodeWalkerArgs{})!
	mut fm := cw.filemap_get(path: dir.path, content_read: true)!

	mut files := []HeropromptFile{}
	mut directories := map[string]bool{} // Use map to avoid duplicates

	// Process each file from the filemap
	for file_path, content in fm.content {
		// Create HeropromptFile for each file
		abs_path := os.join_path(dir.path, file_path)
		file := HeropromptFile{
			id:      rand.uuid_v4()
			name:    os.base(file_path)
			path:    abs_path
			content: content
			created: ourtime.now()
			updated: ourtime.now()
		}
		files << file

		// Extract directory path
		dir_path := os.dir(file_path)
		if dir_path != '.' && dir_path.len > 0 {
			// Add all parent directories
			mut current_dir := dir_path
			for current_dir != '.' && current_dir.len > 0 {
				directories[current_dir] = true
				current_dir = os.dir(current_dir)
			}
		}
	}

	// Convert directories map to array
	mut dir_list := []string{}
	for directory_path, _ in directories {
		dir_list << directory_path
	}

	return DirectoryContent{
		files:       files
		directories: dir_list
		file_count:  files.len
		dir_count:   dir_list.len
	}
}

@[params]
pub struct AddFileParams {
pub mut:
	path string @[required] // Path to file (relative to directory or absolute)
}

// add_file adds a specific file to the directory
// Returns the created HeropromptFile
pub fn (dir &Directory) add_file(args AddFileParams) !HeropromptFile {
	mut file_path := args.path

	// If path is relative, make it relative to directory path
	if !os.is_abs_path(file_path) {
		file_path = os.join_path(dir.path, file_path)
	}

	// Validate file exists
	if !os.exists(file_path) {
		return error('file does not exist: ${file_path}')
	}
	if os.is_dir(file_path) {
		return error('path is a directory, not a file: ${file_path}')
	}

	// Read file content
	content := os.read_file(file_path) or { return error('failed to read file: ${file_path}') }

	// Create HeropromptFile
	file := HeropromptFile{
		id:      rand.uuid_v4()
		name:    os.base(file_path)
		path:    file_path
		content: content
		created: ourtime.now()
		updated: ourtime.now()
	}

	return file
}

@[params]
pub struct SelectFileParams {
pub mut:
	path string @[required] // Path to file (relative to directory or absolute)
}

// select_file marks a file as selected within this directory
// The file path can be relative to the directory or absolute
pub fn (mut dir Directory) select_file(args SelectFileParams) ! {
	// Normalize the path
	mut file_path := args.path
	if !os.is_abs_path(file_path) {
		file_path = os.join_path(dir.path, file_path)
	}
	file_path = os.real_path(file_path)

	// Verify file exists
	if !os.exists(file_path) {
		return error('file does not exist: ${args.path}')
	}

	// Verify file is within this directory
	if !file_path.starts_with(os.real_path(dir.path)) {
		return error('file is not within this directory: ${args.path}')
	}

	// Mark file as selected
	dir.selected_files[file_path] = true
	dir.updated = ourtime.now()
}

// select_all marks all files in this directory and subdirectories as selected
pub fn (mut dir Directory) select_all() ! {
	// Verify directory exists
	if !dir.exists() {
		return error('directory does not exist: ${dir.path}')
	}

	// Get all files in directory
	content := dir.get_contents()!

	// Mark all files as selected
	for file in content.files {
		normalized_path := os.real_path(file.path)
		dir.selected_files[normalized_path] = true
	}

	dir.updated = ourtime.now()
}

@[params]
pub struct DeselectFileParams {
pub mut:
	path string @[required] // Path to file (relative to directory or absolute)
}

// deselect_file marks a file as not selected within this directory
pub fn (mut dir Directory) deselect_file(args DeselectFileParams) ! {
	// Normalize the path
	mut file_path := args.path
	if !os.is_abs_path(file_path) {
		file_path = os.join_path(dir.path, file_path)
	}
	file_path = os.real_path(file_path)

	// Verify file exists
	if !os.exists(file_path) {
		return error('file does not exist: ${args.path}')
	}

	// Verify file is within this directory
	if !file_path.starts_with(os.real_path(dir.path)) {
		return error('file is not within this directory: ${args.path}')
	}

	// Mark file as not selected (remove from map or set to false)
	dir.selected_files.delete(file_path)
	dir.updated = ourtime.now()
}

// deselect_all marks all files in this directory as not selected
pub fn (mut dir Directory) deselect_all() ! {
	// Verify directory exists
	if !dir.exists() {
		return error('directory does not exist: ${dir.path}')
	}

	// Clear all selections
	dir.selected_files.clear()
	dir.updated = ourtime.now()
}

// expand sets the directory as expanded in the UI
pub fn (mut dir Directory) expand() {
	dir.is_expanded = true
	dir.updated = ourtime.now()
}

// collapse sets the directory as collapsed in the UI
pub fn (mut dir Directory) collapse() {
	dir.is_expanded = false
	dir.updated = ourtime.now()
}

@[params]
pub struct AddDirParams {
pub mut:
	path string @[required] // Path to directory (relative to directory or absolute)
	scan bool = true // Whether to automatically scan the directory (default: true)
}

// add_dir adds all files from a specific directory
// Returns DirectoryContent with files from that directory
// If scan=true (default), automatically scans the directory respecting .gitignore
// If scan=false, returns empty DirectoryContent (manual mode)
pub fn (dir &Directory) add_dir(args AddDirParams) !DirectoryContent {
	mut dir_path := args.path

	// If path is relative, make it relative to directory path
	if !os.is_abs_path(dir_path) {
		dir_path = os.join_path(dir.path, dir_path)
	}

	// Validate directory exists
	if !os.exists(dir_path) {
		return error('directory does not exist: ${dir_path}')
	}
	if !os.is_dir(dir_path) {
		return error('path is not a directory: ${dir_path}')
	}

	// If scan is false, return empty content (manual mode)
	if !args.scan {
		return DirectoryContent{
			files:      []HeropromptFile{}
			file_count: 0
			dir_count:  0
		}
	}

	// Use codewalker to scan the directory
	mut cw := codewalker.new(codewalker.CodeWalkerArgs{})!
	mut fm := cw.filemap_get(path: dir_path, content_read: true)!

	mut files := []HeropromptFile{}
	mut directories := map[string]bool{} // Track directories

	// Process each file
	for file_path, content in fm.content {
		abs_path := os.join_path(dir_path, file_path)
		file := HeropromptFile{
			id:      rand.uuid_v4()
			name:    os.base(file_path)
			path:    abs_path
			content: content
			created: ourtime.now()
			updated: ourtime.now()
		}
		files << file

		// Extract directory path
		dir_part := os.dir(file_path)
		if dir_part != '.' && dir_part.len > 0 {
			// Add all parent directories
			mut current_dir := dir_part
			for current_dir != '.' && current_dir.len > 0 {
				directories[current_dir] = true
				current_dir = os.dir(current_dir)
			}
		}
	}

	// Convert directories map to array
	mut dir_list := []string{}
	for directory_path, _ in directories {
		dir_list << directory_path
	}

	return DirectoryContent{
		files:       files
		directories: dir_list
		file_count:  files.len
		dir_count:   dir_list.len
	}
}
