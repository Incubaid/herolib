module core

import incubaid.herolib.core.pathlib
import incubaid.herolib.web.doctree as doctreetools

import incubaid.herolib.data.paramsparser { Params }
import incubaid.herolib.ui.console


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
	doctree     &DocTree @[skip; str: skip]
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
	c.find_links()!
	c.init_git_info()!
}

////////////////////////////////////////////////////////////////////////////////////////////////////////

// Add a page to the collection
fn (mut c Collection) add_page(mut path pathlib.Path) ! {
	name := path.name_fix_no_ext()
	if name in c.pages {
		return error('Page ${name} already exists in collection ${c.name}')
	}
	// Use absolute paths for path_relative to work correctly
	mut col_path := pathlib.get(c.path)
	mut page_abs_path := pathlib.get(path.absolute())
	relativepath := page_abs_path.path_relative(col_path.absolute())!

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
	name := p.name_fix_keepext() // keep extension
	if name in c.files {
		return error('File ${name} already exists in collection ${c.name}')
	}
	// Use absolute paths for path_relative to work correctly
	mut col_path := pathlib.get(c.path)
	mut file_abs_path := pathlib.get(p.absolute())
	relativepath := file_abs_path.path_relative(col_path.absolute())!

	mut file_new := File{
		name:       name
		path:       relativepath // relative path of file in the collection, includes the name
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
pub fn (c Collection) page_get(name_ string) !&Page {
	name := doctreetools.name_fix(name_)
	return c.pages[name] or { return PageNotFound{
		collection: c.name
		page:       name
	} }
}

// Get an image by name
pub fn (c Collection) image_get(name_ string) !&File {
	name := doctreetools.name_fix(name_)
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
pub fn (c Collection) file_get(name_ string) !&File {
	name := doctreetools.name_fix(name_)
	mut f := c.files[name] or { return FileNotFound{
		collection: c.name
		file:       name
	} }
	if f.ftype != .file {
		return error('File `${name}` in collection ${c.name} is not a file')
	}
	return f
}

pub fn (c Collection) file_or_image_get(name_ string) !&File {
	name := doctreetools.name_fix(name_)
	mut f := c.files[name] or { return FileNotFound{
		collection: c.name
		file:       name
	} }
	return f
}

// Check if page exists
pub fn (c Collection) page_exists(name_ string) !bool {
	name := doctreetools.name_fix(name_)
	return name in c.pages
}

// Check if image exists
pub fn (c Collection) image_exists(name_ string) !bool {
	name := doctreetools.name_fix(name_)
	f := c.files[name] or { return false }
	return f.ftype == .image
}

// Check if file exists
pub fn (c Collection) file_exists(name_ string) !bool {
	name := doctreetools.name_fix(name_)
	f := c.files[name] or { return false }
	return f.ftype == .file
}

pub fn (c Collection) file_or_image_exists(name_ string) !bool {
	name := doctreetools.name_fix(name_)
	_ := c.files[name] or { return false }
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

// Check if session can read this collection
pub fn (c Collection) can_read(session Session) bool {
	// If no ACL set, everyone can read
	if c.acl_read.len == 0 {
		return true
	}

	// Get user's groups
	mut doctree := c.doctree
	groups := doctree.groups_get(session)
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
	mut doctree := c.doctree
	groups := doctree.groups_get(session)
	group_names := groups.map(it.name)

	// Check if any of user's groups are in write ACL
	for acl_group in c.acl_write {
		if acl_group in group_names {
			return true
		}
	}

	return false
}
