module core

import incubaid.herolib.core.pathlib




import os

////////////SCANNING FUNCTIONS ?//////////////////////////////////////////////////////

fn (mut c Collection) scan(mut dir pathlib.Path) ! {
	mut entries := dir.list(recursive: false)!

	for mut entry in entries.paths {
		// Skip hidden files/dirs
		if entry.name().starts_with('.') || entry.name().starts_with('_') {
			continue
		}

		if entry.is_dir() {
			// Recursively scan subdirectories
			mut mutable_entry := entry
			c.scan(mut mutable_entry)!
			continue
		}

		// Process files based on extension
		match entry.extension_lower() {
			'md' {
				mut mutable_entry := entry
				c.add_page(mut mutable_entry)!
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
	read_acl_path := '${c.path()!.path}/read.acl'
	if os.exists(read_acl_path) {
		content := os.read_file(read_acl_path)!
		// Split by newlines and normalize
		c.acl_read = content.split('\n')
			.map(it.trim_space())
			.filter(it.len > 0)
			.map(it.to_lower())
	}

	// Look for write.acl in collection directory
	write_acl_path := '${c.path()!.path}/write.acl'
	if os.exists(write_acl_path) {
		content := os.read_file(write_acl_path)!
		// Split by newlines and normalize
		c.acl_write = content.split('\n')
			.map(it.trim_space())
			.filter(it.len > 0)
			.map(it.to_lower())
	}
}

// scan_groups scans the collection's directory for .group files and loads them into memory.
pub fn (mut c Collection) scan_groups() ! {
	if c.name != 'groups' {
		return error('scan_groups only works on "groups" collection')
	}
	mut p := c.path()!
	mut entries := p.list(recursive: false)!

	for mut entry in entries.paths {
		if entry.extension_lower() == 'group' {
			filename := entry.name_fix_no_ext()
			mut visited := map[string]bool{}
			mut group := parse_group_file(filename, c.path()!.path, mut visited)!

			c.doctree.group_add(mut group)!
		}
	}
}
