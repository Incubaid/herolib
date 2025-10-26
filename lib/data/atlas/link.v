module atlas

import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib

// Link represents a markdown link found in content
pub struct Link {
pub mut:
	src                    string // Source content where link was found (what to replace)
	text                   string // Link text [text]
	target                 string // Original link target (the source text)
	line                   int    // Line number where link was found
	target_collection_name string
	target_item_name       string
	status                 LinkStatus
	is_file_link           bool // is the link pointing to a file
	page                   &Page @[skip; str: skip] // Reference to page where this link is found
}

pub enum LinkStatus {
	init
	external
	found
	not_found
	anchor
	error
}

fn (mut self Link) key() string {
	return '${self.target_collection_name}:${self.target_item_name}'
}

// is the link in the same collection as the page containing the link
fn (mut self Link) is_local_in_collection() bool {
	return self.target_collection_name == self.page.collection.name
}

// is the link pointing to an external resource e.g. http, git, mailto, ftp
pub fn (mut self Link) is_external() bool {
	return self.status == .external
}

pub fn (mut self Link) target_page() !&Page {
	if self.status == .external {
		return error('External links do not have a target page')
	}
	return self.page.collection.atlas.page_get(self.key())
}

// Find all markdown links in content
fn (mut p Page) find_links(content string) ![]Link {
	mut links := []Link{}

	mut lines := content.split_into_lines()

	for line_idx, line in lines {
		mut pos := 0
		for {
			mut image_open := line.index_after('!', pos) or { break }

			// Find next [
			open_bracket := line.index_after('[', pos) or { break }

			// Find matching ]
			close_bracket := line.index_after(']', open_bracket) or { break }

			// Check for (
			if close_bracket + 1 >= line.len || line[close_bracket + 1] != `(` {
				pos = close_bracket + 1
				continue
			}

			if image_open + 1 != open_bracket {
				image_open = -1
			}

			// Find matching )
			open_paren := close_bracket + 1
			close_paren := line.index_after(')', open_paren) or { break }

			// Extract link components
			text := line[open_bracket + 1..close_bracket]
			target := line[open_paren + 1..close_paren]

			islink_file_link := (image_open != -1)

			mut link := Link{
				src:          line[open_bracket..close_paren + 1]
				text:         text
				target:       target.trim_space()
				line:         line_idx + 1
				is_file_link: islink_file_link
				page:         &p
			}

			p.parse_link_target(mut link)
			links << link

			pos = close_paren + 1
		}
	}
	return links
}

// Parse link target to extract collection and page
fn (mut p Page) parse_link_target(mut link Link) {
	mut target := link.target

	// Skip external links
	if target.starts_with('http://') || target.starts_with('https://')
		|| target.starts_with('mailto:') || target.starts_with('ftp://') {
		link.status = .external
		return
	}

	// Skip anchors
	if target.starts_with('#') {
		link.status = .anchor
		return
	}

	if target.contains('/') {
		parts9 := target.split('/')
		if parts9.len >= 1 {
			target = parts9[1]
		}
	}

	// Format: $collection:$pagename or $collection:$pagename.md
	if target.contains(':') {
		parts := target.split(':')
		if parts.len >= 2 {
			link.target_collection_name = texttools.name_fix(parts[0])
			link.target_item_name = normalize_page_name(parts[1])
		}
	} else {
		link.target_item_name = normalize_page_name(target).trim_space()
		link.target_collection_name = p.collection.name
	}

	if link.is_file_link == false && !p.collection.atlas.page_exists(link.key()) {
		p.collection.error(
			category:     .invalid_page_reference
			page_key:     p.key()
			message:      'Broken link to `${link.key()}` at line ${link.line}: `${link.src}`'
			show_console: true
		)
		link.status = .not_found
	} else if link.is_file_link && !p.collection.atlas.file_or_image_exists(link.key()) {
		p.collection.error(
			category:     .invalid_file_reference
			page_key:     p.key()
			message:      'Broken file link to `${link.key()}` at line ${link.line}: `${link.src}`'
			show_console: true
		)
		link.status = .not_found
	} else {
		link.status = .found
	}
}

////////////////FIX PAGES FOR THE LINKS///////////////////////

// Fix links in page content - rewrites links with proper relative paths
fn (mut p Page) content_with_fixed_links() !string {
	mut content := p.content(include: false)!
	if p.links.len == 0 {
		return content
	}

	// Process links in reverse order to maintain positions
	for mut link in p.links.reverse() {
		// if page not existing no point in fixing
		if link.status != .found {
			continue
		}
		// if not local then no point in fixing
		if !link.is_local_in_collection() {
			continue
		}
		// Get target page
		mut target_page := link.target_page()!
		mut target_path := target_page.path()!

		relative_path := target_path.path_relative(p.path()!.path)!

		new_link := '[${link.text}](${relative_path})'

		// Replace in content
		content = content.replace(link.src, new_link)
	}

	return content
}

// process_cross_collection_links handles exporting cross-collection references
// It:
// 1. Finds all cross-collection links (collection:page format)
// 2. Copies the target page to the export directory
// 3. Renames the link to avoid conflicts (collectionname_pagename.md)
// 4. Rewrites the link in the content
fn (mut p Page) process_cross_collection_links(mut export_dir pathlib.Path) !string {
	mut c := p.content(include: true)!

	mut links := p.find_links(c)!

	// Process links in reverse order to	 maintain string positions
	for mut link in links.reverse() {
		if link.status != .found {
			continue
		}
		mut target_page := link.target_page()!
		mut target_path := target_page.path()!

		// Copy target page with renamed filename
		exported_filename := '${target_page.collection.name}_${target_page.name}.md'
		page_content := target_page.content(include: true)!

		mut exported_file := pathlib.get_file(
			path:   '${export_dir.path}/${exported_filename}'
			create: true
		)!
		exported_file.write(page_content)!

		// Update link in source content
		new_link := '[${link.text}](${exported_filename})'
		c = c.replace(link.src, new_link)

		panic('need to do for files too')
	}

	// for mut link in links.reverse() {
	// 	if link.status != . {
	// 		continue
	// 	}
	// }

	return c
}

/////////////TOOLS//////////////////////////////////

// Normalize page name (remove .md, apply name_fix)
fn normalize_page_name(name string) string {
	mut clean := name
	if clean.ends_with('.md') {
		clean = clean[0..clean.len - 3]
	}
	return texttools.name_fix(clean)
}
