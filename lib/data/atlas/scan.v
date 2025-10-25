module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.texttools
import incubaid.herolib.ui.console
// import incubaid.herolib.core.base
// import incubaid.herolib.develop.gittools
import incubaid.herolib.data.paramsparser
import os

// Scan a directory for collections
fn (mut a Atlas) scan_directory(mut dir pathlib.Path, ignore_ []string) ! {
	console.print_item('Scanning directory: ${dir.path}')
	if !dir.is_dir() {
		return error('Path is not a directory: ${dir.path}')
	}
	mut ignore := ignore_.clone()
	ignore = ignore.map(it.to_lower())
	// Check if this directory is a collection
	if is_collection_dir(dir) {
		collection_name := get_collection_name(mut dir)!
		if collection_name.to_lower() in ignore {
			return
		}
		a.add_collection(path: dir.path, name: collection_name)!
		return
	}

	// Scan subdirectories
	mut entries := dir.list(recursive: false)!
	for mut entry in entries.paths {
		if !entry.is_dir() || should_skip_dir(entry) {
			continue
		}

		mut mutable_entry := entry
		a.scan_directory(mut mutable_entry, ignore)!
	}
}

// Detect git repository URL for a collection
fn (mut c Collection) detect_git_url() ! {
	mut current_path := c.path

	// Walk up directory tree to find .git
	mut git_repo := current_path.parent_find('.git') or {
		// No git repo found
		return
	}

	if git_repo.path == '' {
		return
	}

	// Get git origin URL
	origin_url := os.execute('cd ${git_repo.path} && git config --get remote.origin.url')
	if origin_url.exit_code == 0 {
		c.git_url = origin_url.output.trim_space()
	}

	// Get current branch
	branch_result := os.execute('cd ${git_repo.path} && git branch --show-current')
	if branch_result.exit_code == 0 {
		c.git_branch = branch_result.output.trim_space()
	}
}

// Check if directory is a collection
fn is_collection_dir(path pathlib.Path) bool {
	return path.file_exists('.collection')
}

// Get collection name from .collection file
fn get_collection_name(mut path pathlib.Path) !string {
	mut collection_name := path.name()
	mut filepath := path.file_get('.collection')!

	content := filepath.read()!
	if content.trim_space() != '' {
		mut params := paramsparser.parse(content)!
		if params.exists('name') {
			collection_name = params.get('name')!
		}
	}

	return texttools.name_fix(collection_name)
}

// Check if directory should be skipped
fn should_skip_dir(entry pathlib.Path) bool {
	name := entry.name()
	return name.starts_with('.') || name.starts_with('_')
}

// Scan collection directory for files
fn (mut c Collection) scan() ! {
	c.scan_path(mut c.path)!
	c.scan_acl()! // NEW: scan ACL files
	c.detect_git_url() or {
		console.print_debug('Could not detect git URL for collection ${c.name}: ${err}')
	}
}

fn (mut c Collection) scan_path(mut dir pathlib.Path) ! {
	mut entries := dir.list(recursive: false)!

	for mut entry in entries.paths {
		// Skip hidden files/dirs
		if entry.name().starts_with('.') || entry.name().starts_with('_') {
			continue
		}

		if entry.is_dir() {
			// Recursively scan subdirectories
			mut mutable_entry := entry
			c.scan_path(mut mutable_entry)!
			continue
		}

		// Process files based on extension
		match entry.extension_lower() {
			'md' {
				mut mutable_entry := entry
				c.add_page(mut mutable_entry)!
			}
			'png', 'jpg', 'jpeg', 'gif', 'svg' {
				mut mutable_entry := entry
				c.add_image(mut mutable_entry)!
			}
			else {
				mut mutable_entry := entry
				c.add_file(mut mutable_entry)!
			}
		}
	}
}

// Scan for ACL files
fn (mut c Collection) scan_acl() ! {
	// Look for read.acl in collection directory
	read_acl_path := '${c.path.path}/read.acl'
	if os.exists(read_acl_path) {
		content := os.read_file(read_acl_path)!
		// Split by newlines and normalize
		c.acl_read = content.split('\n')
			.map(it.trim_space())
			.filter(it.len > 0)
			.map(it.to_lower())
	}

	// Look for write.acl in collection directory
	write_acl_path := '${c.path.path}/write.acl'
	if os.exists(write_acl_path) {
		content := os.read_file(write_acl_path)!
		// Split by newlines and normalize
		c.acl_write = content.split('\n')
			.map(it.trim_space())
			.filter(it.len > 0)
			.map(it.to_lower())
	}
}
