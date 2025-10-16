module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.data.paramsparser
import incubaid.herolib.core.texttools
import os

@[params]
pub struct ScanArgs {
pub mut:
	path string @[required]
	save bool = true // save atlas after scan
}

// Scan a directory for collections
fn (mut a Atlas) scan_directory(mut dir pathlib.Path) ! {
	if !dir.is_dir() {
		return error('Path is not a directory: ${dir.path}')
	}

	// Check if this directory is a collection
	if is_collection_dir(dir) {
		collection_name := get_collection_name(mut dir)!
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
		a.scan_directory(mut mutable_entry)!
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
