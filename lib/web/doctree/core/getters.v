module core

import incubaid.herolib.web.doctree

// Get a page from any collection using format "collection:page"
pub fn (a DocTree) page_get(key string) !&Page {
	parts := key.split(':')
	if parts.len != 2 {
		return error('Invalid page key format. Use "collection:page" in page_get')
	}

	col := a.get_collection(parts[0])!
	return col.page_get(parts[1])!
}

// Get an image from any collection using format "collection:image"
pub fn (a DocTree) image_get(key string) !&File {
	parts := key.split(':')
	if parts.len != 2 {
		return error('Invalid image key format. Use "collection:image" in image_get')
	}

	col := a.get_collection(parts[0])!
	return col.image_get(parts[1])!
}

// Get a file from any collection using format "collection:file"
pub fn (a DocTree) file_get(key string) !&File {
	parts := key.split(':')
	if parts.len != 2 {
		return error('Invalid file key format. Use "collection:file" in file_get')
	}

	col := a.get_collection(parts[0])!
	return col.file_get(parts[1])!
}

// Get a file (can be image) from any collection using format "collection:file"
pub fn (a DocTree) file_or_image_get(key string) !&File {
	c, n := doctree.key_parse(key)!
	col := a.get_collection(c)!
	return col.file_or_image_get(n)!
}

// Check if page exists
pub fn (a DocTree) page_exists(key string) !bool {
	c, n := doctree.key_parse(key)!
	col := a.get_collection(c) or { return false }
	return col.page_exists(n)
}

// Check if image exists
pub fn (a DocTree) image_exists(key string) !bool {
	c, n := doctree.key_parse(key)!
	col := a.get_collection(c) or { return false }
	return col.image_exists(n)
}

// Check if file exists
pub fn (a DocTree) file_exists(key string) !bool {
	c, n := doctree.key_parse(key)!
	col := a.get_collection(c) or { return false }
	return col.file_exists(n)
}

pub fn (a DocTree) file_or_image_exists(key string) !bool {
	c, n := doctree.key_parse(key)!
	col := a.get_collection(c) or { return false }
	return col.file_or_image_exists(n)
}

// List all pages in DocTree
pub fn (a DocTree) list_pages() map[string][]string {
	mut result := map[string][]string{}

	for col_name, col in a.collections {
		mut page_names := []string{}
		for page_name, _ in col.pages {
			page_names << page_name
		}
		page_names.sort()
		result[col_name] = page_names
	}

	return result
}
