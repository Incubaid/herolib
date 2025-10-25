module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.texttools
import incubaid.herolib.core.base
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
	name         string       @[required]
	path         pathlib.Path @[required]
	pages        map[string]&Page
	images       map[string]&File
	files        map[string]&File
	atlas        &Atlas @[skip; str: skip]
	errors       []CollectionError
	error_cache  map[string]bool
	git_url      string // NEW: URL to the git repository for editing
	git_branch   string // NEW: Git branch for this collection
	git_edit_url string @[skip]
	acl_read     []string // Group names allowed to read (lowercase)
	acl_write    []string // Group names allowed to write (lowercase)
}

@[params]
pub struct CollectionNewArgs {
pub mut:
	name string @[required]
	path string @[required]
}

// Create a new collection
fn (mut self Atlas) new_collection(args CollectionNewArgs) !Collection {
	mut name := texttools.name_fix(args.name)
	mut path := pathlib.get_dir(path: args.path)!

	mut col := Collection{
		name:        name
		path:        path
		atlas:       &self // Set atlas reference
		error_cache: map[string]bool{}
	}

	return col
}

// Add a page to the collection
fn (mut c Collection) add_page(mut p pathlib.Path) ! {
	name := p.name_fix_no_ext()

	if name in c.pages {
		return error('Page ${name} already exists in collection ${c.name}')
	}

	p_new := new_page(
		name:            name
		path:            p
		collection_name: c.name
		collection:      &c
	)!

	c.pages[name] = &p_new
}

// Add an image to the collection
fn (mut c Collection) add_image(mut p pathlib.Path) ! {
	name := p.name_fix_no_ext()

	if name in c.images {
		return error('Image ${name} already exists in collection ${c.name}')
	}

	mut img := new_file(path: p)!
	c.images[name] = &img
}

// Add a file to the collection
fn (mut c Collection) add_file(mut p pathlib.Path) ! {
	name := p.name_fix_no_ext()

	if name in c.files {
		return error('File ${name} already exists in collection ${c.name}')
	}

	mut file := new_file(path: p)!
	c.files[name] = &file
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
	return c.images[name] or { return FileNotFound{
		collection: c.name
		file:       name
	} }
}

// Get a file by name
pub fn (c Collection) file_get(name string) !&File {
	return c.files[name] or { return FileNotFound{
		collection: c.name
		file:       name
	} }
}

// Check if page exists
pub fn (c Collection) page_exists(name string) bool {
	return name in c.pages
}

// Check if image exists
pub fn (c Collection) image_exists(name string) bool {
	return name in c.images
}

// Check if file exists
pub fn (c Collection) file_exists(name string) bool {
	return name in c.files
}

@[params]
pub struct CollectionExportArgs {
pub mut:
	destination pathlib.Path @[required]
	reset       bool = true
	include     bool = true // process includes during export
	redis       bool = true
}

// Export a single collection
pub fn (mut c Collection) export(args CollectionExportArgs) ! {
	// Create collection directory
	mut col_dir := pathlib.get_dir(
		path:   '${args.destination.path}/${c.name}'
		create: true
	)!

	if args.reset {
		col_dir.empty()!
	}

	// Write .collection file
	mut cfile := pathlib.get_file(
		path:   '${col_dir.path}/.collection'
		create: true
	)!
	cfile.write("name:${c.name} src:'${c.path.path}'")!

	// Export pages (process includes if requested)
	for _, mut page in c.pages {
		content := page.content(include: args.include)!
		mut dest_file := pathlib.get_file(
			path:   '${col_dir.path}/${page.name}.md'
			create: true
		)!
		dest_file.write(content)!

		if args.redis {
			mut context := base.context()!
			mut redis := context.redis()!
			redis.hset('atlas:${c.name}', page.name, '${page.name}.md')!
		}
	}

	// Export images
	if c.images.len > 0 {
		img_dir := pathlib.get_dir(
			path:   '${col_dir.path}/img'
			create: true
		)!

		for _, mut img in c.images {
			dest_path := '${img_dir.path}/${img.file_name()}'
			img.path.copy(dest: dest_path)!

			if args.redis {
				mut context := base.context()!
				mut redis := context.redis()!
				redis.hset('atlas:${c.name}', img.file_name(), 'img/${img.file_name()}')!
			}
		}
	}

	// Export files
	if c.files.len > 0 {
		files_dir := pathlib.get_dir(
			path:   '${col_dir.path}/files'
			create: true
		)!

		for _, mut file in c.files {
			dest_path := '${files_dir.path}/${file.file_name()}'
			file.path.copy(dest: dest_path)!

			if args.redis {
				mut context := base.context()!
				mut redis := context.redis()!
				redis.hset('atlas:${c.name}', file.file_name(), 'files/${file.file_name()}')!
			}
		}
	}

	// Store collection metadata in Redis
	if args.redis {
		mut context := base.context()!
		mut redis := context.redis()!
		redis.hset('atlas:path', c.name, col_dir.path)!
	}
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
		page.validate_links()!
	}
}

// Fix all links in collection (rewrite files)
pub fn (mut c Collection) fix_links() ! {
	for _, mut page in c.pages {
		// Read original content
		content := page.read_content()!

		// Fix links
		fixed_content := page.fix_links(content)!

		// Write back if changed
		if fixed_content != content {
			page.path.write(fixed_content)!
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
