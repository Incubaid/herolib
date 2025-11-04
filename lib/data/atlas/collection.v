module atlas

import incubaid.herolib.core.pathlib
// import incubaid.herolib.core.texttools
import incubaid.herolib.develop.gittools
import incubaid.herolib.data.paramsparser { Params }
import incubaid.herolib.ui.console
import os

pub struct Session {
pub mut:
	user   string // username
	email  string // user's email (lowercase internally)
	params Params // additional context from request/webserver
}

@[heap]
pub struct Collection {
pub mut:
	name        string
	path        string // absolute path
	pages       map[string]&Page
	files       map[string]&File
	atlas       &Atlas @[skip; str: skip]
	errors      []CollectionError
	error_cache map[string]bool
	git_url     string
	acl_read    []string // Group names allowed to read (lowercase)
	acl_write   []string // Group names allowed to write (lowercase)
}

// Read content without processing includes
pub fn (mut c Collection) path() !pathlib.Path {
	return pathlib.get_dir(path: c.path, create: false)!
}

fn (mut c Collection) init_pre() ! {
	mut p := mut c.path()!
	c.scan(mut p)!
	c.scan_acl()!
}

fn (mut c Collection) init_post() ! {
	c.validate_links()!
	c.init_git_info()!
}

////////////////////////////////////////////////////////////////////////////////////////////////////////

// Add a page to the collection
fn (mut c Collection) add_page(mut path pathlib.Path) ! {
	// Use name_fix_no_underscore_no_ext to ensure consistent naming
	// This ensures token_system.md and tokensystem.md both become 'tokensystem'
	name := path.name_fix_no_underscore_no_ext()
	if name in c.pages {
		return error('Page ${name} already exists in collection ${c.name}')
	}
	relativepath := path.path_relative(c.path()!.path)!

	mut p_new := Page{
		name:            name
		path:            relativepath
		collection_name: c.name
		collection:      &c
	}

	c.pages[name] = &p_new
}

// Add an image to the collection
fn (mut c Collection) add_file(mut p pathlib.Path) ! {
	name := p.name_fix_keepext()
	if name in c.files {
		return error('Page ${name} already exists in collection ${c.name}')
	}
	relativepath := p.path_relative(c.path()!.path)!

	mut file_new := File{
		name:       name
		ext:        p.extension_lower()
		path:       relativepath // relative path of file in the collection
		collection: &c
	}

	if p.is_image() {
		file_new.ftype = .image
	} else {
		file_new.ftype = .file
	}
	c.files[name] = &file_new
}

// Get a page by name
pub fn (c Collection) page_get(name string) !&Page {
	return c.pages[name] or { return PageNotFound{
		collection: c.name
		page:       name
	} }
}

// Get an image by name
pub fn (c Collection) image_get(name string) !&File {
	mut img := c.files[name] or { return FileNotFound{
		collection: c.name
		file:       name
	} }
	if img.ftype != .image {
		return error('File `${name}` in collection ${c.name} is not an image')
	}
	return img
}

// Get a file by name
pub fn (c Collection) file_get(name string) !&File {
	mut f := c.files[name] or { return FileNotFound{
		collection: c.name
		file:       name
	} }
	if f.ftype != .file {
		return error('File `${name}` in collection ${c.name} is not a file')
	}
	return f
}

pub fn (c Collection) file_or_image_get(name string) !&File {
	mut f := c.files[name] or { return FileNotFound{
		collection: c.name
		file:       name
	} }
	return f
}

// Check if page exists
pub fn (c Collection) page_exists(name string) bool {
	return name in c.pages
}

// Check if image exists
pub fn (c Collection) image_exists(name string) bool {
	f := c.files[name] or { return false }
	return f.ftype == .image
}

// Check if file exists
pub fn (c Collection) file_exists(name string) bool {
	f := c.files[name] or { return false }
	return f.ftype == .file
}

pub fn (c Collection) file_or_image_exists(name string) bool {
	f := c.files[name] or { return false }
	return true
}

@[params]
pub struct CollectionErrorArgs {
pub mut:
	category     CollectionErrorCategory @[required]
	message      string                  @[required]
	page_key     string
	file         string
	show_console bool // Show error in console immediately
	log_error    bool = true // Log to errors array (default: true)
}

// Report an error, avoiding duplicates based on hash
pub fn (mut c Collection) error(args CollectionErrorArgs) {
	// Create error struct
	err := CollectionError{
		category: args.category
		page_key: args.page_key
		message:  args.message
		file:     args.file
	}

	// Calculate hash for deduplication
	hash := err.hash()

	// Check if this error was already reported
	if hash in c.error_cache {
		return
	}

	// Mark this error as reported
	c.error_cache[hash] = true

	// Log to errors array if requested
	if args.log_error {
		c.errors << err
	}

	// Show in console if requested
	if args.show_console {
		console.print_stderr('[${c.name}] ${err.str()}')
	}
}

// Get all errors
pub fn (c Collection) get_errors() []CollectionError {
	return c.errors
}

// Check if collection has errors
pub fn (c Collection) has_errors() bool {
	return c.errors.len > 0
}

// Clear all errors
pub fn (mut c Collection) clear_errors() {
	c.errors = []CollectionError{}
	c.error_cache = map[string]bool{}
}

// Get error summary by category
pub fn (c Collection) error_summary() map[CollectionErrorCategory]int {
	mut summary := map[CollectionErrorCategory]int{}

	for err in c.errors {
		summary[err.category] = summary[err.category] + 1
	}

	return summary
}

// Print all errors to console
pub fn (c Collection) print_errors() {
	if c.errors.len == 0 {
		console.print_green('Collection ${c.name}: No errors')
		return
	}

	console.print_header('Collection ${c.name} - Errors (${c.errors.len})')

	for err in c.errors {
		console.print_stderr('  ${err.str()}')
	}
}

// Validate all links in collection
pub fn (mut c Collection) validate_links() ! {
	for _, mut page in c.pages {
		content := page.content(include: true)!
		page.links = page.find_links(content)! // will walk over links see if errors and add errors
	}
}

// Fix all links in collection (rewrite files)
pub fn (mut c Collection) fix_links() ! {
	for _, mut page in c.pages {
		// Read original content
		content := page.content()!

		// Fix links
		fixed_content := page.content_with_fixed_links()!

		// Write back if changed
		if fixed_content != content {
			mut p := page.path()!
			p.write(fixed_content)!
		}
	}
}

// Check if session can read this collection
pub fn (c Collection) can_read(session Session) bool {
	// If no ACL set, everyone can read
	if c.acl_read.len == 0 {
		return true
	}

	// Get user's groups
	mut atlas := c.atlas
	groups := atlas.groups_get(session)
	group_names := groups.map(it.name)

	// Check if any of user's groups are in read ACL
	for acl_group in c.acl_read {
		if acl_group in group_names {
			return true
		}
	}

	return false
}

// Check if session can write this collection
pub fn (c Collection) can_write(session Session) bool {
	// If no ACL set, no one can write
	if c.acl_write.len == 0 {
		return false
	}

	// Get user's groups
	mut atlas := c.atlas
	groups := atlas.groups_get(session)
	group_names := groups.map(it.name)

	// Check if any of user's groups are in write ACL
	for acl_group in c.acl_write {
		if acl_group in group_names {
			return true
		}
	}

	return false
}

// Detect git repository URL for a collection
fn (mut c Collection) init_git_info() ! {
	mut current_path := c.path()!

	// Walk up directory tree to find .git
	mut git_repo := current_path.parent_find('.git') or {
		// No git repo found
		return
	}

	if git_repo.path == '' {
		panic('Unexpected empty git repo path')
	}

	mut gs := gittools.new()!
	mut p := c.path()!
	mut location := gs.gitlocation_from_path(p.path)!

	r := os.execute_opt('cd ${p.path} && git branch --show-current')!

	location.branch_or_tag = r.output.trim_space()

	c.git_url = location.web_url()!
}

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

			c.atlas.group_add(mut group)!
		}
	}
}
