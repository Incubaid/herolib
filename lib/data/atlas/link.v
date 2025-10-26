module atlas

import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import os

// Link represents a markdown link found in content
pub struct Link {
pub mut:
	text       string // Link text [text]
	target     string // Original link target
	line       int    // Line number
	col_start  int    // Column start position
	col_end    int    // Column end position
	collection string // Target collection (if specified)
	page       string // Target page name (normalized)
	is_local   bool   // Whether link points to local page
	valid      bool   // Whether link target exists
}

// Find all markdown links in content
pub fn find_links(content string) []Link {
	mut links := []Link{}
	lines := content.split_into_lines()
	
	for line_idx, line in lines {
		mut pos := 0
		for {
			// Find next [
			open_bracket := line.index_after('[', pos) or { break }
			
			// Find matching ]
			close_bracket := line.index_after(']', open_bracket) or { break }
			
			// Check for (
			if close_bracket + 1 >= line.len || line[close_bracket + 1] != `(` {
				pos = close_bracket + 1
				continue
			}
			
			// Find matching )
			open_paren := close_bracket + 1
			close_paren := line.index_after(')', open_paren) or { break }
			
			// Extract link components
			text := line[open_bracket + 1..close_bracket]
			target := line[open_paren + 1..close_paren]
			
			mut link := Link{
				text:      text
				target:    target.trim_space()
				line:      line_idx + 1
				col_start: open_bracket
				col_end:   close_paren + 1
			}
			
			parse_link_target(mut link)
			links << link
			
			pos = close_paren + 1
		}
	}
	
	return links
}

// Parse link target to extract collection and page
fn parse_link_target(mut link Link) {
	target := link.target
	
	// Skip external links
	if target.starts_with('http://') || target.starts_with('https://') 
		|| target.starts_with('mailto:') || target.starts_with('ftp://') {
		return
	}
	
	// Skip anchors
	if target.starts_with('#') {
		return
	}
	
	link.is_local = true
	
	// Format: $collection:$pagename or $collection:$pagename.md
	if target.contains(':') {
		parts := target.split(':')
		if parts.len >= 2 {
			link.collection = texttools.name_fix(parts[0])
			link.page = normalize_page_name(parts[1])
		}
		return
	}
	
	// For all other formats, extract filename from path (ignore path components)
	// Handles: $page, path/to/$page, /path/to/$page, /path/to/$page.md
	filename := os.base(target)
	link.page = normalize_page_name(filename)
}

// Normalize page name (remove .md, apply name_fix)
fn normalize_page_name(name string) string {
	mut clean := name
	if clean.ends_with('.md') {
		clean = clean[0..clean.len - 3]
	}
	return texttools.name_fix(clean)
}

// Validate links in page
pub fn (mut p Page) validate_links() ! {
	content := p.read_content()!
	links := find_links(content)
	
	for link in links {
		if !link.is_local {
			continue
		}
		
		// Determine target collection
		mut target_collection := link.collection
		if target_collection == '' {
			target_collection = p.collection_name
		}
		
		// Check if page exists
		page_key := '${target_collection}:${link.page}'
		if !p.collection.atlas.page_exists(page_key) {
			p.collection.error(
				category:     .invalid_page_reference
				page_key:     p.key()
				message:      'Broken link to `${page_key}` at line ${link.line}: [${link.text}](${link.target})'
				show_console: false
			)
		}
	}
}

// Fix links in page content - rewrites links with proper relative paths
pub fn (mut p Page) fix_links(content string) !string {
	links := find_links(content)
	if links.len == 0 {
		return content
	}
	
	mut result := content
	
	// Process links in reverse order to maintain positions
	for link in links.reverse() {
		if !link.is_local || link.page == '' {
			continue
		}
		
		// Determine target collection
		mut target_collection := link.collection
		if target_collection == '' {
			target_collection = p.collection_name
		}
		
		// Only fix links within same collection
		if target_collection != p.collection_name {
			continue
		}
		
		// Get target page
		page_key := '${target_collection}:${link.page}'
		mut target_page := p.collection.atlas.page_get(page_key) or {
			// Skip if page doesn't exist - error already reported in validate
			continue
		}
		
		// Calculate relative path
		relative_path := calculate_relative_path(mut p.path, mut target_page.path)
		
		// Build replacement
		old_link := '[${link.text}](${link.target})'
		new_link := '[${link.text}](${relative_path})'
		
		// Replace in content
		result = result.replace(old_link, new_link)
	}
	
	return result
}

// Calculate relative path from source file to target file with .md extension
fn calculate_relative_path(mut from pathlib.Path, mut to pathlib.Path) string {
	from_dir := from.path_dir()
	to_dir := to.path_dir()
	to_name := to.name_fix_no_ext()
	
	// If in same directory, just return filename with .md
	if from_dir == to_dir {
		return '${to_name}.md'
	}
	
	// Split paths into parts
	from_parts := from_dir.split(os.path_separator).filter(it != '')
	to_parts := to_dir.split(os.path_separator).filter(it != '')
	
	// Find common base
	mut common_len := 0
	for i := 0; i < from_parts.len && i < to_parts.len; i++ {
		if from_parts[i] == to_parts[i] {
			common_len = i + 1
		} else {
			break
		}
	}
	
	// Build relative path
	mut rel_parts := []string{}
	
	// Add ../ for each directory we need to go up
	up_count := from_parts.len - common_len
	for _ in 0..up_count {
		rel_parts << '..'
	}
	
	// Add path down to target
	for i := common_len; i < to_parts.len; i++ {
		rel_parts << to_parts[i]
	}
	
	// Add filename with .md extension
	rel_parts << '${to_name}.md'
	
	return rel_parts.join('/')
}
// process_cross_collection_links handles exporting cross-collection references
// It:
// 1. Finds all cross-collection links (collection:page format)
// 2. Copies the target page to the export directory
// 3. Renames the link to avoid conflicts (collectionname_pagename.md)
// 4. Rewrites the link in the content
pub fn process_cross_collection_links(
	content string,
	source_col Collection,
	mut export_dir pathlib.Path,
	atlas &Atlas
) !string {
	mut result := content
	links := find_links(content)
	
	// Process links in reverse order to maintain string positions
	for link in links.reverse() {
		if !link.is_local || link.page == '' {
			continue
		}
		
		// Determine target collection
		mut target_collection := link.collection
		if target_collection == '' {
			target_collection = source_col.name
		}
		
		// Skip same-collection links (already handled by fix_links)
		if target_collection == source_col.name {
			continue
		}
		
		// Get the target page
		page_key := '${target_collection}:${link.page}'
		mut target_page := atlas.page_get(page_key) or {
			// Link target doesn't exist, leave as-is
			continue
		}
		
		// Copy target page with renamed filename
		exported_filename := '${target_collection}_${target_page.name}.md'
		page_content := target_page.content(include: true)!
		
		mut exported_file := pathlib.get_file(
			path:   '${export_dir.path}/${exported_filename}'
			create: true
		)!
		exported_file.write(page_content)!
		
		// Update link in source content
		old_link := '[${link.text}](${link.target})'
		new_link := '[${link.text}](${exported_filename})'
		result = result.replace(old_link, new_link)
	}
	
	return result
}

// process_cross_collection_images handles exporting images from other collections
// Similar to process_cross_collection_links but for images
pub fn process_cross_collection_images(
	content string,
	source_col Collection,
	mut export_dir pathlib.Path,
	atlas &Atlas
) !string {
	// Extract image references: ![alt](collection:image.png)
	// Copy images to img/ directory with renamed filename
	// Update references in content
	
	// Pattern: ![alt](collection:filename.ext)
	// Update to: ![alt](img/collection_filename.ext)
	
	mut result := content
	
	// Find image markdown syntax: ![alt](path)
	lines := result.split_into_lines()
	mut processed_lines := []string{}
	
	for line in lines {
		mut processed_line := line
		
		// Find image references - look for ![...](...) with cross-collection prefix
		// This is a simplified approach; full regex would be better
		if line.contains('![') && line.contains(']:') {
			// Extract and process cross-collection image references
			// For each reference like [imagename](othercol:image.png)
			// Copy from othercol to img/ as othercol_image.png
			// Update link to img/othercol_image.png
			
			// TODO: Implement image extraction and copying
		}
		
		processed_lines << processed_line
	}
	
	return processed_lines.join_lines()
}