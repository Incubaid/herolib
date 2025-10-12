module doctreeclient

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.texttools
import os

// List of recognized image file extensions
const image_extensions = ['.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.bmp', '.tiff', '.ico']

// Error types for DocTreeClient
pub enum DocTreeError {
	collection_not_found
	page_not_found
	file_not_found
	image_not_found
}

// get_page_path returns the path for a page in a collection
pub fn (mut c DocTreeClient) get_page_path(collection_name string, page_name string) !string {
	// Apply name_fix to collection and page names
	fixed_collection_name := texttools.name_fix(collection_name)
	fixed_page_name := texttools.name_fix(page_name)

	// Check if the collection exists
	collection_path := c.redis.hget('doctree:path', fixed_collection_name) or {
		return error('${DocTreeError.collection_not_found}: Collection "${collection_name}" not found')
	}

	// Get the relative path of the page within the collection
	rel_path := c.redis.hget('doctree:${fixed_collection_name}', fixed_page_name) or {
		return error('${DocTreeError.page_not_found}: Page "${page_name}" not found in collection "${collection_name}"')
	}

	// Combine the collection path with the relative path
	return os.join_path(collection_path, rel_path)
}

// get_file_path returns the path for a file in a collection
pub fn (mut c DocTreeClient) get_file_path(collection_name string, file_name string) !string {
	// Apply name_fix to collection and file names
	fixed_collection_name := texttools.name_fix(collection_name)
	fixed_file_name := texttools.name_fix(file_name)

	// Check if the collection exists
	collection_path := c.redis.hget('doctree:path', fixed_collection_name) or {
		return error('${DocTreeError.collection_not_found}: Collection "${collection_name}" not found')
	}

	// Get the relative path of the file within the collection
	rel_path := c.redis.hget('doctree:${fixed_collection_name}', fixed_file_name) or {
		return error('${DocTreeError.file_not_found}: File "${file_name}" not found in collection "${collection_name}"')
	}

	// Combine the collection path with the relative path
	return os.join_path(collection_path, rel_path)
}

// get_image_path returns the path for an image in a collection
pub fn (mut c DocTreeClient) get_image_path(collection_name string, image_name string) !string {
	// Apply name_fix to collection and image names
	fixed_collection_name := texttools.name_fix(collection_name)
	fixed_image_name := texttools.name_fix(image_name)

	// Check if the collection exists
	collection_path := c.redis.hget('doctree:path', fixed_collection_name) or {
		return error('${DocTreeError.collection_not_found}: Collection "${collection_name}" not found')
	}

	// Get the relative path of the image within the collection
	rel_path := c.redis.hget('doctree:${fixed_collection_name}', fixed_image_name) or {
		return error('${DocTreeError.image_not_found}: Image "${image_name}" not found in collection "${collection_name}"')
	}

	if rel_path == '' {
		return error('${DocTreeError.image_not_found}: Image "${image_name}" found in collection "${collection_name}" but its path is empty in Redis.')
	}

	// console.print_debug('get_image_path: rel_path for "${image_name}": "${rel_path}"')

	// Combine the collection path with the relative path
	return os.join_path(collection_path, rel_path)
}

// page_exists checks if a page exists in a collection
pub fn (mut c DocTreeClient) page_exists(collection_name string, page_name string) bool {
	// Apply name_fix to collection and page names
	fixed_collection_name := texttools.name_fix(collection_name)
	fixed_page_name := texttools.name_fix(page_name)

	// Check if the collection exists
	e := c.redis.hexists('doctree:path', fixed_collection_name) or { return false }
	if !e {
		return false
	}

	// Check if the page exists in the collection
	return c.redis.hexists('doctree:${fixed_collection_name}', fixed_page_name) or { false }
}

// file_exists checks if a file exists in a collection
pub fn (mut c DocTreeClient) file_exists(collection_name string, file_name string) bool {
	// Apply name_fix to collection and file names
	fixed_collection_name := texttools.name_fix(collection_name)
	fixed_file_name := texttools.name_fix(file_name)

	// Check if the collection exists
	e := c.redis.hexists('doctree:path', fixed_collection_name) or { return false }
	if !e {
		return false
	}

	// Check if the file exists in the collection
	return c.redis.hexists('doctree:${fixed_collection_name}', fixed_file_name) or { false }
}

// image_exists checks if an image exists in a collection
pub fn (mut c DocTreeClient) image_exists(collection_name string, image_name string) bool {
	// Apply name_fix to collection and image names
	fixed_collection_name := texttools.name_fix(collection_name)
	fixed_image_name := texttools.name_fix(image_name)

	// Check if the collection exists
	e := c.redis.hexists('doctree:path', fixed_collection_name) or { return false }
	if !e {
		return false
	}

	// Check if the image exists in the collection
	return c.redis.hexists('doctree:${fixed_collection_name}', fixed_image_name) or { false }
}

// get_page_content returns the content of a page in a collection
pub fn (mut c DocTreeClient) get_page_content(collection_name string, page_name string) !string {
	// Apply name_fix to collection and page names
	fixed_collection_name := texttools.name_fix(collection_name)
	fixed_page_name := texttools.name_fix(page_name)

	// Get the path for the page
	page_path := c.get_page_path(fixed_collection_name, fixed_page_name)!

	// Use pathlib to read the file content
	mut path := pathlib.get_file(path: page_path)!

	// Check if the file exists
	if !path.exists() {
		return error('${DocTreeError.page_not_found}: Page file "${page_path}" does not exist on disk')
	}

	// Read and return the file content
	return path.read()!
}

// list_collections returns a list of all collection names
pub fn (mut c DocTreeClient) list_collections() ![]string {
	// Get all collection names from Redis
	return c.redis.hkeys('doctree:path')!
}

// list_pages returns a list of all page names in a collection
pub fn (mut c DocTreeClient) list_pages(collection_name string) ![]string {
	// Apply name_fix to collection name
	fixed_collection_name := texttools.name_fix(collection_name)

	// Check if the collection exists
	if !(c.redis.hexists('doctree:path', fixed_collection_name) or { false }) {
		return error('${DocTreeError.collection_not_found}: Collection "${collection_name}" not found')
	}

	// Get all keys from the collection hash
	all_keys := c.redis.hkeys('doctree:${fixed_collection_name}')!

	// Filter out only the page names (those without file extensions)
	mut page_names := []string{}
	for key in all_keys {
		if !key.contains('.') {
			page_names << key
		}
	}

	return page_names
}

// list_files returns a list of all file names in a collection
pub fn (mut c DocTreeClient) list_files(collection_name string) ![]string {
	// Apply name_fix to collection name
	fixed_collection_name := texttools.name_fix(collection_name)

	// Check if the collection exists
	if !(c.redis.hexists('doctree:path', fixed_collection_name) or { false }) {
		return error('${DocTreeError.collection_not_found}: Collection "${collection_name}" not found')
	}

	// Get all keys from the collection hash
	all_keys := c.redis.hkeys('doctree:${fixed_collection_name}')!

	// Filter out only the file names (those with file extensions, but not images)
	mut file_names := []string{}
	for key in all_keys {
		// Get the value (path) for this key
		value := c.redis.hget('doctree:${fixed_collection_name}', key) or { continue }

		// Check if the value contains a file extension (has a dot)
		if value.contains('.') {
			// Check if the value ends with any of the image extensions
			mut is_image := false
			for ext in image_extensions {
				if value.ends_with(ext) {
					is_image = true
					break
				}
			}

			// Add to file_names if it's not an image and not a page
			if !is_image && !value.ends_with('.md') {
				file_names << key
			}
		}
	}

	return file_names
}

// list_images returns a list of all image names in a collection
pub fn (mut c DocTreeClient) list_images(collection_name string) ![]string {
	// Apply name_fix to collection name
	fixed_collection_name := texttools.name_fix(collection_name)

	// Check if the collection exists
	if !(c.redis.hexists('doctree:path', fixed_collection_name) or { false }) {
		return error('${DocTreeError.collection_not_found}: Collection "${collection_name}" not found')
	}

	// Get all keys from the collection hash
	all_keys := c.redis.hkeys('doctree:${fixed_collection_name}')!

	// Filter out only the image names (those whose values end with image extensions)
	mut image_names := []string{}
	for key in all_keys {
		// Get the value (path) for this key
		value := c.redis.hget('doctree:${fixed_collection_name}', key) or { continue }

		// Check if the value ends with any of the image extensions
		for ext in image_extensions {
			if value.ends_with(ext) {
				image_names << key
				break
			}
		}
	}

	return image_names
}

// list_pages_map returns a map of collection names to a list of page names within that collection.
// The structure is map[collectionname][]pagename.
pub fn (mut c DocTreeClient) list_pages_map() !map[string][]string {
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
pub fn (mut c DocTreeClient) list_markdown() !string {
	mut markdown_output := ''
	pages_map := c.list_pages_map()!

	if pages_map.len == 0 {
		return 'No collections or pages found in this doctree.'
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

// get_page_paths returns the path of a page and the paths of its linked images.
// Returns (page_path, image_paths)
pub fn (mut c DocTreeClient) get_page_paths(collection_name string, page_name string) !(string, []string) {
	// Get the page path
	page_path := c.get_page_path(collection_name, page_name)!
	page_content := c.get_page_content(collection_name, page_name)!

	// Extract image names from the page content
	image_names := extract_image_links(page_content, true)!
	// println(image_names)

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

// copy_page copies a page and its linked images to a specified destination.
pub fn (mut c DocTreeClient) copy_images(collection_name string, page_name string, destination_path string) ! {
	// Get the page path and linked image paths
	page_path, image_paths := c.get_page_paths(collection_name, page_name)!

	// println('copy_page: Linked image paths: ${image_paths}')

	// Ensure the destination directory exists
	os.mkdir_all(destination_path)!

	// // Copy the page file
	// page_file_name := os.base(page_path)
	// dest_page_path := os.join_path(destination_path, page_file_name)
	// os.cp(page_path, dest_page_path)!

	// Create an 'img' subdirectory within the destination
	images_dest_path := os.join_path(destination_path, 'img')
	os.mkdir_all(images_dest_path)!

	// Copy each linked image
	for image_path in image_paths {
		// println(image_path)
		image_file_name := os.base(image_path)
		dest_image_path := os.join_path(images_dest_path, image_file_name)
		// console.print_debug('copy_page: Copying image file from "${image_path}" to "${dest_image_path}"')
		os.cp(image_path, dest_image_path)!
		// console.print_debug('Copy Image file "${image_file_name}" copied.')
	}
}
