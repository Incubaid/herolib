module client

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.texttools
import incubaid.herolib.ui.console
import os
import json
import incubaid.herolib.core.redisclient

// get_page_links returns all links found in a page and pages linked to it (recursive)
// This includes transitive links through page-to-page references
// External links, files, and images do not recurse further
pub fn (mut c AtlasClient) get_page_links(collection_name string, page_name string) ![]LinkMetadata {
	mut visited := map[string]bool{}
	mut all_links := []LinkMetadata{}
	c.collect_page_links_recursive(collection_name, page_name, mut visited, mut all_links)!
	return all_links
}


// collect_page_links_recursive is the internal recursive implementation
// It traverses all linked pages and collects all links found
// 
// Thread safety: Each call to get_page_links gets its own visited map
// Circular references are prevented by tracking visited pages
//
// Link types behavior:
// - .page links: Recursively traverse to get links from the target page
// - .file and .image links: Included in results but not recursively expanded
// - .external links: Included in results but not recursively expanded
fn (mut c AtlasClient) collect_page_links_recursive(collection_name string, page_name string, mut visited map[string]bool, mut all_links []LinkMetadata) ! {
	// Create unique key for cycle detection
	page_key := '${collection_name}:${page_name}'
	
	// Prevent infinite loops on circular page references
	// Example: Page A → Page B → Page A
	if page_key in visited {
		return
	}
	visited[page_key] = true
	
	// Get collection metadata
	metadata := c.get_collection_metadata(collection_name)!
	fixed_page_name := texttools.name_fix(page_name)

	// Find the page in metadata
	if fixed_page_name !in metadata.pages {
		return error('page_not_found: Page "${page_name}" not found in collection metadata, for collection: "${collection_name}"')
	}
	
	page_meta := metadata.pages[fixed_page_name]
	
	// Add all direct links from this page to the result
	// This includes: pages, files, images, and external links
	all_links << page_meta.links
	
	// Recursively traverse only page-to-page links
	for link in page_meta.links {
		// Only recursively process links to other pages within the doctree
		// Skip external links (http, https, mailto, etc.)
		// Skip file and image links (these don't have "contained" links)
		if link.file_type != .page || link.status == .external {
			continue
		}
		
		// Recursively collect links from the target page
		c.collect_page_links_recursive(link.target_collection_name, link.target_item_name, mut visited, mut all_links) or {
			// If we encounter an error (e.g., target page doesn't exist in metadata),
			// we continue processing other links rather than failing completely
			// This provides graceful degradation for broken link references
			continue
		}
	}
}

// get_image_links returns all image links found in a page and related pages (recursive)
// This is a convenience function that filters get_page_links to only image links
pub fn (mut c AtlasClient) get_image_links(collection_name string, page_name string) ![]LinkMetadata {
	all_links := c.get_page_links(collection_name, page_name)!
	mut image_links := []LinkMetadata{}
	
	for link in all_links {
		if link.file_type == .image {
			image_links << link
		}
	}
	
	return image_links
}

// get_file_links returns all file links (non-image) found in a page and related pages (recursive)
// This is a convenience function that filters get_page_links to only file links
pub fn (mut c AtlasClient) get_file_links(collection_name string, page_name string) ![]LinkMetadata {
	all_links := c.get_page_links(collection_name, page_name)!
	mut file_links := []LinkMetadata{}
	
	for link in all_links {
		if link.file_type == .file {
			file_links << link
		}
	}
	
	return file_links
}

// get_page_link_targets returns all page-to-page link targets found in a page and related pages
// This is a convenience function that filters get_page_links to only page links
pub fn (mut c AtlasClient) get_page_link_targets(collection_name string, page_name string) ![]LinkMetadata {
	all_links := c.get_page_links(collection_name, page_name)!
	mut page_links := []LinkMetadata{}
	
	for link in all_links {
		if link.file_type == .page && link.status != .external {
			page_links << link
		}
	}
	
	return page_links
}