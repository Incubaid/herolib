module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.texttools
import incubaid.herolib.core.base
import os

@[heap]
pub struct Collection {
pub mut:
	name   string       @[required]
	path   pathlib.Path @[required]
	pages  map[string]&Page
	images map[string]&File
	files  map[string]&File
	atlas  &Atlas @[skip; str: skip] // Reference to parent atlas for include resolution
	errors []CollectionError
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
		name:  name
		path:  path
		atlas: &self // Set atlas reference
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
