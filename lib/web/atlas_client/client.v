module atlas_client

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.texttools
import os
import json

// List of recognized image file extensions
const image_extensions = ['.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.bmp', '.tiff', '.ico']

// CollectionMetadata represents the metadata stored in meta/{collection}.json
pub struct CollectionMetadata {
pub mut:
	name   string
	path   string
	pages  map[string]PageMetadata
	files  map[string]FileMetadata
	errors []ErrorMetadata
}

pub struct PageMetadata {
pub mut:
	name            string
	path            string
	collection_name string
	links           []LinkMetadata
}

pub struct FileMetadata {
pub mut:
	name string
	path string
}

pub struct LinkMetadata {
pub mut:
	src                    string
	text                   string
	target                 string
	line                   int
	target_collection_name string
	target_item_name       string
	status                 string
	is_file_link           bool
	is_image_link          bool
}

pub struct ErrorMetadata {
pub mut:
	category string
	page_key string
	message  string
	line     int
}

// get_page_path returns the path for a page in a collection
// Pages are stored in {export_dir}/content/{collection}/{page}.md
pub fn (mut c AtlasClient) get_page_path(collection_name string, page_name string) !string {
	// Apply name normalization
	fixed_collection_name := texttools.name_fix(collection_name)
	fixed_page_name := texttools.name_fix(page_name)

	// Check if export directory exists
	if !os.exists(c.export_dir) {
		return c.error_export_dir_not_found(export_dir: c.export_dir)
	}

	// Construct the page path
	page_path := os.join_path(c.export_dir, 'content', fixed_collection_name, '${fixed_page_name}.md')

	// Check if the page file exists
	if !os.exists(page_path) {
		return c.error_page_not_found(
			collection_name: collection_name
			page_name:       page_name
		)
	}

	return page_path
}

// get_file_path returns the path for a file in a collection
// Files are stored in {export_dir}/content/{collection}/{filename}
pub fn (mut c AtlasClient) get_file_path(collection_name string, file_name string) !string {
	// Apply name normalization
	fixed_collection_name := texttools.name_fix(collection_name)
	// Files keep their original names with extensions
	fixed_file_name := texttools.name_fix_keepext(file_name)

	// Check if export directory exists
	if !os.exists(c.export_dir) {
		return c.error_export_dir_not_found(export_dir: c.export_dir)
	}

	// Construct the file path
	file_path := os.join_path(c.export_dir, 'content', fixed_collection_name, fixed_file_name)

	// Check if the file exists
	if !os.exists(file_path) {
		return c.error_file_not_found(
			collection_name: collection_name
			file_name:       file_name
		)
	}

	return file_path
}

// get_image_path returns the path for an image in a collection
// Images are stored in {export_dir}/content/{collection}/{imagename}
pub fn (mut c AtlasClient) get_image_path(collection_name string, image_name string) !string {
	// Apply name normalization
	fixed_collection_name := texttools.name_fix_no_underscore_no_ext(collection_name)
	// Images keep their original names with extensions
	fixed_image_name := texttools.name_fix_keepext(image_name)

	// Check if export directory exists
	if !os.exists(c.export_dir) {
		return c.error_export_dir_not_found(export_dir: c.export_dir)
	}

	// Construct the image path
	image_path := os.join_path(c.export_dir, 'content', fixed_collection_name, fixed_image_name)

	// Check if the image exists
	if !os.exists(image_path) {
		return c.error_image_not_found(
			collection_name: collection_name
			image_name:      image_name
		)
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
		return c.error_page_file_not_exists(page_path: page_path)
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
		return c.error_invalid_export_structure(content_dir: content_dir)
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
	// Apply name normalization
	fixed_collection_name := texttools.name_fix(collection_name)

	collection_dir := os.join_path(c.export_dir, 'content', fixed_collection_name)

	// Check if collection directory exists
	if !os.exists(collection_dir) {
		return c.error_collection_not_found(collection_name: collection_name)
	}

	// Get all files that are not .md and not images
	mut file_names := []string{}
	entries := os.ls(collection_dir)!

	for entry in entries {
		entry_path := os.join_path(collection_dir, entry)

		// Skip directories
		if os.is_dir(entry_path) {
			continue
		}

		// Skip .md files (pages)
		if entry.ends_with('.md') {
			continue
		}

		// Check if it's an image
		mut is_image := false
		for ext in image_extensions {
			if entry.ends_with(ext) {
				is_image = true
				break
			}
		}

		// Add to file_names if it's not an image
		if !is_image {
			file_names << entry
		}
	}

	return file_names
}

// list_images returns a list of all image names in a collection
pub fn (mut c AtlasClient) list_images(collection_name string) ![]string {
	// Apply name normalization
	fixed_collection_name := texttools.name_fix(collection_name)

	collection_dir := os.join_path(c.export_dir, 'content', fixed_collection_name)

	// Check if collection directory exists
	if !os.exists(collection_dir) {
		return c.error_collection_not_found(collection_name: collection_name)
	}

	// Get all image files
	mut image_names := []string{}
	entries := os.ls(collection_dir)!

	for entry in entries {
		entry_path := os.join_path(collection_dir, entry)

		// Skip directories
		if os.is_dir(entry_path) {
			continue
		}

		// Check if it's an image
		for ext in image_extensions {
			if entry.ends_with(ext) {
				image_names << entry
				break
			}
		}
	}

	return image_names
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

// list_markdown returns the collections and their pages in markdown format.
pub fn (mut c AtlasClient) list_markdown() !string {
	mut markdown_output := ''
	pages_map := c.list_pages_map()!

	if pages_map.len == 0 {
		return 'No collections or pages found in this atlas export.'
	}

	mut sorted_collections := pages_map.keys()
	sorted_collections.sort()

	for col_name in sorted_collections {
		page_names := pages_map[col_name]
		markdown_output += '## ${col_name}\n'
		if page_names.len == 0 {
			markdown_output += '  * No pages in this collection.\n'
		} else {
			for page_name in page_names {
				markdown_output += '  * ${page_name}\n'
			}
		}
		markdown_output += '\n' // Add a newline for spacing between collections
	}
	return markdown_output
}

// get_collection_metadata reads and parses the metadata JSON file for a collection
// Metadata is stored in {export_dir}/meta/{collection}.json
pub fn (mut c AtlasClient) get_collection_metadata(collection_name string) !CollectionMetadata {
	// Apply name normalization
	fixed_collection_name := texttools.name_fix_no_underscore_no_ext(collection_name)

	meta_path := os.join_path(c.export_dir, 'meta', '${fixed_collection_name}.json')

	// Check if metadata file exists
	if !os.exists(meta_path) {
		return c.error_collection_not_found_at(
			collection_name: collection_name
			path:            meta_path
		)
	}

	// Read and parse the JSON file
	content := os.read_file(meta_path)!
	metadata := json.decode(CollectionMetadata, content)!

	return metadata
}

// get_page_links returns the links found in a page by reading the metadata
pub fn (mut c AtlasClient) get_page_links(collection_name string, page_name string) ![]LinkMetadata {
	// Get collection metadata
	metadata := c.get_collection_metadata(collection_name)!

	// Apply name normalization to page name
	fixed_page_name := texttools.name_fix_no_underscore_no_ext(page_name)

	// Find the page in metadata
	if fixed_page_name in metadata.pages {
		return metadata.pages[fixed_page_name].links
	}

	return c.error_page_not_found_in_metadata(
		collection_name: collection_name
		page_name:       page_name
	)
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

// get_page_paths returns the path of a page and the paths of its linked images.
// Returns (page_path, image_paths)
// This is compatible with the doctreeclient API
pub fn (mut c AtlasClient) get_page_paths(collection_name string, page_name string) !(string, []string) {
	// Get the page path
	page_path := c.get_page_path(collection_name, page_name)!
	page_content := c.get_page_content(collection_name, page_name)!

	// Extract image names from the page content
	image_names := extract_image_links(page_content, true)!

	mut image_paths := []string{}
	for image_name in image_names {
		// Get the path for each image
		image_path := c.get_image_path(collection_name, image_name) or {
			// If an image is not found, log a warning and continue, don't fail the whole operation
			return error('Error: Linked image "${image_name}" not found in collection "${collection_name}". Skipping.')
		}
		image_paths << image_path
	}

	return page_path, image_paths
}

// copy_images copies all images linked in a page to a destination directory
// This is compatible with the doctreeclient API
pub fn (mut c AtlasClient) copy_images(collection_name string, page_name string, destination_path string) ! {
	// Get the page path and linked image paths
	_, image_paths := c.get_page_paths(collection_name, page_name)!

	// Ensure the destination directory exists
	os.mkdir_all(destination_path)!

	// Create an 'img' subdirectory within the destination
	images_dest_path := os.join_path(destination_path, 'img')
	os.mkdir_all(images_dest_path)!

	// Copy each linked image
	for image_path in image_paths {
		image_file_name := os.base(image_path)
		dest_image_path := os.join_path(images_dest_path, image_file_name)
		os.cp(image_path, dest_image_path)!
	}
}
