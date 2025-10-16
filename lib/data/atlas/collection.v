module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.texttools

@[heap]
pub struct Collection {
pub mut:
	name   string       @[required]
	path   pathlib.Path @[required]
	pages  map[string]&Page
	images map[string]&File
	files  map[string]&File
	atlas  &Atlas @[skip]
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
		atlas: &self
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
