module atlas

// Get a page from any collection using format "collection:page"
pub fn (a Atlas) page_get(key string) !&Page {
	parts := key.split(':')
	if parts.len != 2 {
		return error('Invalid page key format. Use "collection:page"')
	}

	col := a.get_collection(parts[0])!
	return col.page_get(parts[1])!
}

// Get an image from any collection using format "collection:image"
pub fn (a Atlas) image_get(key string) !&File {
	parts := key.split(':')
	if parts.len != 2 {
		return error('Invalid image key format. Use "collection:image"')
	}

	col := a.get_collection(parts[0])!
	return col.image_get(parts[1])!
}

// Get a file from any collection using format "collection:file"
pub fn (a Atlas) file_get(key string) !&File {
	parts := key.split(':')
	if parts.len != 2 {
		return error('Invalid file key format. Use "collection:file"')
	}

	col := a.get_collection(parts[0])!
	return col.file_get(parts[1])!
}

// Check if page exists
pub fn (a Atlas) page_exists(key string) bool {
	parts := key.split(':')
	if parts.len != 2 {
		return false
	}

	col := a.get_collection(parts[0]) or { return false }
	return col.page_exists(parts[1])
}

// Check if image exists
pub fn (a Atlas) image_exists(key string) bool {
	parts := key.split(':')
	if parts.len != 2 {
		return false
	}

	col := a.get_collection(parts[0]) or { return false }
	return col.image_exists(parts[1])
}

// Check if file exists
pub fn (a Atlas) file_exists(key string) bool {
	parts := key.split(':')
	if parts.len != 2 {
		return false
	}

	col := a.get_collection(parts[0]) or { return false }
	return col.file_exists(parts[1])
}

// List all pages in Atlas
pub fn (a Atlas) list_pages() map[string][]string {
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
