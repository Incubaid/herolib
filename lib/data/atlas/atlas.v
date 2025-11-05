module atlas

import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console
import incubaid.herolib.data.paramsparser

@[heap]
pub struct Atlas {
pub mut:
	name        string
	collections map[string]&Collection
	groups      map[string]&Group // name -> Group mapping
}

// Create a new collection
fn (mut self Atlas) add_collection(mut path pathlib.Path) !Collection {
	mut name := path.name_fix_no_ext()
	mut filepath := path.file_get('.collection')!
	content := filepath.read()!
	if content.trim_space() != '' {
		mut params := paramsparser.parse(content)!
		if params.exists('name') {
			name = params.get('name')!
		}
	}
	// Normalize collection name
	name = texttools.name_fix(name)
	console.print_item("Adding collection '${name}' to Atlas '${self.name}' at path '${path.path}'")

	if name in self.collections {
		return error('Collection ${name} already exists in Atlas ${self.name}')
	}

	mut c := Collection{
		name:        name
		path:        path.path // absolute path
		atlas:       &self     // Set atlas reference
		error_cache: map[string]bool{}
	}

	c.init_pre()!

	self.collections[name] = &c

	return c
}

// Get a collection by name
pub fn (a Atlas) get_collection(name string) !&Collection {
	return a.collections[name] or {
		return CollectionNotFound{
			name: name
			msg:  'Collection not found in Atlas ${a.name}'
		}
	}
}

// Validate all links in all collections
pub fn (mut a Atlas) init_post() ! {
	for _, mut col in a.collections {
		col.init_post()!
	}
}

// Add a group to the atlas
pub fn (mut a Atlas) group_add(mut group Group) ! {
	if group.name in a.groups {
		return error('Group ${group.name} already exists')
	}
	a.groups[group.name] = &group
}

// Get a group by name
pub fn (a Atlas) group_get(name string) !&Group {
	name_lower := texttools.name_fix(name)
	return a.groups[name_lower] or { return error('Group ${name} not found') }
}

// Get all groups matching a session's email
pub fn (a Atlas) groups_get(session Session) []&Group {
	mut matching := []&Group{}

	email_lower := session.email.to_lower()

	for _, group in a.groups {
		if group.matches(email_lower) {
			matching << group
		}
	}

	return matching
}

//////////////////SCAN

// Scan a path for collections

@[params]
pub struct ScanArgs {
pub mut:
	path   string @[required]
	ignore []string // list of directory names to ignore
}

pub fn (mut a Atlas) scan(args ScanArgs) ! {
	mut path := pathlib.get_dir(path: args.path)!
	mut ignore := args.ignore.clone()
	ignore = ignore.map(it.to_lower())
	a.scan_(mut path, ignore)!
}

// Scan a directory for collections
fn (mut a Atlas) scan_(mut dir pathlib.Path, ignore_ []string) ! {
	console.print_item('Scanning directory: ${dir.path}')
	if !dir.is_dir() {
		return error('Path is not a directory: ${dir.path}')
	}

	// Check if this directory is a collection
	if dir.file_exists('.collection') {
		collname := dir.name_fix_no_ext()
		if collname.to_lower() in ignore_ {
			return
		}
		mut col := a.add_collection(mut dir)!
		if collname == 'groups' {
			col.scan_groups()!
		}
		return
	}

	// Scan subdirectories
	mut entries := dir.list(recursive: false)!
	for mut entry in entries.paths {
		if !entry.is_dir() || should_skip_dir(entry) {
			continue
		}

		mut mutable_entry := entry
		a.scan_(mut mutable_entry, ignore_)!
	}
}

// Check if directory should be skipped
fn should_skip_dir(entry pathlib.Path) bool {
	name := entry.name()
	return name.starts_with('.') || name.starts_with('_')
}
