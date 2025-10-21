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