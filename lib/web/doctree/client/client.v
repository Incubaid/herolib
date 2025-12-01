module client

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.texttools
import incubaid.herolib.ui.console
import os
import json
import incubaid.herolib.core.redisclient

// AtlasClient provides access to DocTree-exported documentation collections
// It reads from both the exported directory structure and Redis metadata
pub struct AtlasClient {
pub mut:
	redis      &redisclient.Redis
	export_dir string // Path to the doctree export directory (contains content/ and meta/)
}

// get_page_path returns the path for a page in a collection
// Pages are stored in {export_dir}/content/{collection}/{page}.md
pub fn (mut c AtlasClient) get_page_path(collection_name string, page_name string) !string {
	// Apply name normalization
	fixed_collection_name := texttools.name_fix(collection_name)
	fixed_page_name := texttools.name_fix(page_name)

	// Check if export directory exists
	if !os.exists(c.export_dir) {
		return error('export_dir_not_found: Export directory "${c.export_dir}" not found')
	}

	// Construct the page path
	page_path := os.join_path(c.export_dir, 'content', fixed_collection_name, '${fixed_page_name}.md')

	// Check if the page file exists
	if !os.exists(page_path) {
		return error('page_not_found: Page "${page_name}" not found in collection "${collection_name}"')
	}

	return page_path
}

// get_file_path returns the path for a file in a collection
// Files are stored in {export_dir}/content/{collection}/{filename}
pub fn (mut c AtlasClient) get_file_path(collection_name_ string, file_name_ string) !string {
	collection_name := texttools.name_fix(collection_name_)
	file_name := texttools.name_fix(file_name_)

	// Check if export directory exists
	if !os.exists(c.export_dir) {
		return error('export_dir_not_found: Export directory "${c.export_dir}" not found')
	}

	// Construct the file path
	file_path := os.join_path(c.export_dir, 'content', collection_name, 'files', file_name)

	// Check if the file exists
	if !os.exists(file_path) {
		return error('file_not_found:"${file_path}" File "${file_name}" not found in collection "${collection_name}"')
	}

	return file_path
}

// get_image_path returns the path for an image in a collection
// Images are stored in {export_dir}/content/{collection}/{imagename}
pub fn (mut c AtlasClient) get_image_path(collection_name_ string, image_name_ string) !string {
	// Apply name normalization
	collection_name := texttools.name_fix(collection_name_)
	// Images keep their original names with extensions
	image_name := texttools.name_fix(image_name_)

	// Check if export directory exists
	if !os.exists(c.export_dir) {
		return error('export_dir_not_found: Export directory "${c.export_dir}" not found')
	}

	// Construct the image path
	image_path := os.join_path(c.export_dir, 'content', collection_name, 'img', image_name)

	// Check if the image exists
	if !os.exists(image_path) {
		return error('image_not_found":"${image_path}" Image "${image_name}" not found in collection "${collection_name}"')
	}

	return image_path
}

// page_exists checks if a page exists in a collection
pub fn (mut c AtlasClient) page_exists(collection_name string, page_name string) bool {
	// Try to get the page path - if it succeeds, the page exists
	_ := c.get_page_path(collection_name, page_name) or { return false }
	return true
}

// file_exists checks if a file exists in a collection
pub fn (mut c AtlasClient) file_exists(collection_name string, file_name string) bool {
	// Try to get the file path - if it succeeds, the file exists
	_ := c.get_file_path(collection_name, file_name) or { return false }
	return true
}

// image_exists checks if an image exists in a collection
pub fn (mut c AtlasClient) image_exists(collection_name string, image_name string) bool {
	// Try to get the image path - if it succeeds, the image exists
	_ := c.get_image_path(collection_name, image_name) or { return false }
	return true
}

// get_page_content returns the content of a page in a collection
pub fn (mut c AtlasClient) get_page_content(collection_name string, page_name string) !string {
	// Get the path for the page
	page_path := c.get_page_path(collection_name, page_name)!

	// Use pathlib to read the file content
	mut path := pathlib.get_file(path: page_path)!

	// Check if the file exists
	if !path.exists() {
		return error('page_not_found: Page file "${page_path}" does not exist on disk')
	}

	// Read and return the file content
	return path.read()!
}

// list_collections returns a list of all collection names
// Collections are directories in {export_dir}/content/
pub fn (mut c AtlasClient) list_collections() ![]string {
	content_dir := os.join_path(c.export_dir, 'content')

	// Check if content directory exists
	if !os.exists(content_dir) {
		return error('invalid_export_structure: Content directory not found at "${content_dir}"')
	}

	// Get all subdirectories in content/
	mut collections := []string{}
	entries := os.ls(content_dir)!

	for entry in entries {
		entry_path := os.join_path(content_dir, entry)
		if os.is_dir(entry_path) {
			collections << entry
		}
	}

	return collections
}

// list_pages returns a list of all page names in a collection
// Uses metadata to get the authoritative list of pages that belong to this collection
pub fn (mut c AtlasClient) list_pages(collection_name string) ![]string {
	// Get metadata which contains the authoritative list of pages
	metadata := c.get_collection_metadata(collection_name)!

	// Extract page names from metadata
	mut page_names := []string{}
	for page_name, _ in metadata.pages {
		page_names << page_name
	}

	return page_names
}

// list_files returns a list of all file names in a collection (excluding pages and images)
pub fn (mut c AtlasClient) list_files(collection_name string) ![]string {
	metadata := c.get_collection_metadata(collection_name)!
	mut file_names := []string{}
	for file_name, file_meta in metadata.files {
		if !file_meta.path.starts_with('img/') { // Exclude images
			file_names << file_name
		}
	}
	return file_names
}

// list_images returns a list of all image names in a collection
pub fn (mut c AtlasClient) list_images(collection_name string) ![]string {
	metadata := c.get_collection_metadata(collection_name)!
	mut images := []string{}
	for file_name, file_meta in metadata.files {
		if file_meta.path.starts_with('img/') {
			images << file_name
		}
	}
	return images
}

// list_pages_map returns a map of collection names to a list of page names within that collection.
// The structure is map[collectionname][]pagename.
pub fn (mut c AtlasClient) list_pages_map() !map[string][]string {
	mut result := map[string][]string{}
	collections := c.list_collections()!

	for col_name in collections {
		mut page_names := c.list_pages(col_name)!
		page_names.sort()
		result[col_name] = page_names
	}
	return result
}

// get_collection_metadata reads and parses the metadata JSON file for a collection
// Metadata is stored in {export_dir}/meta/{collection}.json
pub fn (mut c AtlasClient) get_collection_metadata(collection_name string) !CollectionMetadata {
	// Apply name normalization
	fixed_collection_name := texttools.name_fix(collection_name)

	meta_path := os.join_path(c.export_dir, 'meta', '${fixed_collection_name}.json')

	// Check if metadata file exists
	if !os.exists(meta_path) {
		return error('collection_not_found: Metadata file for collection "${collection_name}" not found at "${meta_path}"')
	}

	// Read and parse the JSON file
	content := os.read_file(meta_path)!

	metadata := json.decode(CollectionMetadata, content)!

	return metadata
}

// get_collection_errors returns the errors for a collection from metadata
pub fn (mut c AtlasClient) get_collection_errors(collection_name string) ![]ErrorMetadata {
	metadata := c.get_collection_metadata(collection_name)!
	return metadata.errors
}

// has_errors checks if a collection has any errors
pub fn (mut c AtlasClient) has_errors(collection_name string) bool {
	errors := c.get_collection_errors(collection_name) or { return false }
	return errors.len > 0
}

pub fn (mut c AtlasClient) copy_collection(collection_name string, destination_path string) ! {
	// TODO: list over all pages, links & files and copy them to destination
}

// will copy all pages linked from a page to a destination directory as well as the page itself
pub fn (mut c AtlasClient) copy_pages(collection_name string, page_name string, destination_path string) ! {
	// TODO: copy page itself

	// Get page links from metadata
	links := c.get_page_links(collection_name, page_name)!

	// Create img subdirectory
	mut img_dest := pathlib.get_dir(path: '${destination_path}', create: true)!

	// Copy only image links
	for link in links {
		if link.file_type != .page {
			continue
		}
		if link.status == .external {
			continue
		}
		// Get image path and copy
		img_path := c.get_page_path(link.target_collection_name, link.target_item_name)!
		mut src := pathlib.get_file(path: img_path)!
		src.copy(dest: '${img_dest.path}/${src.name_fix_no_ext()}')!
		console.print_debug(' ********. Copied page: ${src.path} to ${img_dest.path}/${src.name_fix_no_ext()}')
	}
}

pub fn (mut c AtlasClient) copy_images(collection_name string, page_name string, destination_path string) ! {
	// Get page links from metadata
	links := c.get_page_links(collection_name, page_name)!

	// Create img subdirectory
	mut img_dest := pathlib.get_dir(path: '${destination_path}/img', create: true)!

	// Copy only image links
	for link in links {
		if link.file_type != .image {
			continue
		}
		if link.status == .external {
			continue
		}
		// Get image path and copy
		img_path := c.get_image_path(link.target_collection_name, link.target_item_name)!
		mut src := pathlib.get_file(path: img_path)!
		src.copy(dest: '${img_dest.path}/${src.name_fix_no_ext()}')!
		// console.print_debug('Copied image: ${src.path} to ${img_dest.path}/${src.name_fix()}')
	}
}

// copy_files copies all non-image files from a page to a destination directory
// Files are placed in {destination}/files/ subdirectory
// Only copies files referenced in the page (via links)
pub fn (mut c AtlasClient) copy_files(collection_name string, page_name string, destination_path string) ! {
	// Get page links from metadata
	links := c.get_page_links(collection_name, page_name)!

	// Create files subdirectory
	mut files_dest := pathlib.get_dir(path: '${destination_path}/files', create: true)!

	// Copy only file links (non-image files)
	for link in links {
		if link.file_type != .file {
			continue
		}
		if link.status == .external {
			continue
		}
		// println(link)
		// Get file path and copy
		file_path := c.get_file_path(link.target_collection_name, link.target_item_name)!
		mut src := pathlib.get_file(path: file_path)!
		// src.copy(dest: '${files_dest.path}/${src.name_fix_no_ext()}')!
		console.print_debug('Copied file: ${src.path} to ${files_dest.path}/${src.name_fix_no_ext()}')
	}
}
