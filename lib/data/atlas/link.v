module atlas

import incubaid.herolib.core.texttools

// Link represents a markdown link found in content
pub struct Link {
pub mut:
	src                    string // Source content where link was found (what to replace)
	text                   string // Link text [text]
	target                 string // Original link target (the source text)
	line                   int    // Line number where link was found (1-based)
	pos                    int    // Character position in line where link starts (0-based)
	target_collection_name string
	target_item_name       string
	status                 LinkStatus
	is_file_link           bool // is the link pointing to a file
	is_image_link          bool // is the link pointing to an image
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

pub fn (mut self Link) target_file() !&File {
	if self.status == .external {
		return error('External links do not have a target file')
	}
	return self.page.collection.atlas.file_or_image_get(self.key())
}

// Find all markdown links in content
fn (mut p Page) find_links(content string) ![]Link {
	mut links := []Link{}

	mut lines := content.split_into_lines()

	for line_idx, line in lines {
		// println('Processing line ${line_idx + 1}: ${line}')
		mut pos := 0
		for {
			mut image_open := line.index_after('!', pos) or { -1 }

			// Find next [
			open_bracket := line.index_after('[', pos) or { break }

			// Find matching ]
			close_bracket := line.index_after(']', open_bracket) or { break }

			// Check for (
			if close_bracket + 1 >= line.len || line[close_bracket + 1] != `(` {
				pos = close_bracket + 1
				// println('no ( after ]: skipping, ${line}')
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

			mut is_image_link := (image_open != -1)

			mut is_file_link := false

			// if no . in file then it means it's a page link (binaries with . are not supported in other words)
			if target.contains('.') && (!target.trim_space().to_lower().ends_with('.md')) {
				is_file_link = true
				is_image_link = false // means it's a file link, not an image link
			}

			// Store position - use image_open if it's an image, otherwise open_bracket
			link_start_pos := if is_image_link { image_open } else { open_bracket }

			mut link := Link{
				src:           line[open_bracket..close_paren + 1]
				text:          text
				target:        target.trim_space()
				line:          line_idx + 1
				pos:           link_start_pos
				is_file_link:  is_file_link
				is_image_link: is_image_link
				page:          &p
			}

			p.parse_link_target(mut link)
			if link.status == .external {
				link.is_file_link = false
				link.is_image_link = false
			}
			links << link

			pos = close_paren + 1
		}
	}
	return links
}

// Parse link target to extract collection and page
fn (mut p Page) parse_link_target(mut link Link) {
	mut target := link.target.to_lower().trim_space()

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

@[params]
pub struct FixLinksArgs {
	include          bool // Process includes before fixing links
	cross_collection bool // Process cross-collection links (for export)
	export_mode      bool // Use export-style simple paths instead of filesystem paths
}

// Fix links in page content - rewrites links with proper relative paths
fn (mut p Page) content_with_fixed_links(args FixLinksArgs) !string {
	mut content := p.content(include: args.include)!

	// Get links - either re-find them (if includes processed) or use cached
	mut links := if args.include {
		p.find_links(content)! // Re-find links in processed content
	} else {
		p.links // Use cached links from validation
	}

	// Filter and transform links
	for mut link in links {
		// Skip invalid links
		if link.status != .found {
			continue
		}

		// Skip cross-collection links unless enabled
		if !args.cross_collection && !link.is_local_in_collection() {
			continue
		}

		// Calculate new link path
		new_link := p.calculate_link_path(mut link, args) or { continue }

		// Build the complete link markdown
		prefix := if link.is_file_link { '!' } else { '' }
		new_link_md := '${prefix}[${link.text}](${new_link})'

		// Replace in content
		content = content.replace(link.src, new_link_md)
	}

	return content
}

// calculate_link_path returns the relative path for a link
fn (mut p Page) calculate_link_path(mut link Link, args FixLinksArgs) !string {
	if args.export_mode {
		// Export mode: simple flat structure
		return p.export_link_path(mut link)!
	}
	// Fix mode: filesystem paths
	return p.filesystem_link_path(mut link)!
}

// export_link_path calculates path for export (self-contained: all references are local)
fn (mut p Page) export_link_path(mut link Link) !string {
	mut target_filename := ''

	if link.is_file_link {
		mut tf := link.target_file()!
		target_filename = tf.name
	} else {
		mut tp := link.target_page()!
		target_filename = '${tp.name}.md'
	}

	// For self-contained exports, all links are local (cross-collection pages are copied)
	return target_filename
}

// filesystem_link_path calculates path using actual filesystem paths
fn (mut p Page) filesystem_link_path(mut link Link) !string {
	source_path := p.path()!

	mut target_path := if link.is_file_link {
		mut tf := link.target_file()!
		tf.path()!
	} else {
		mut tp := link.target_page()!
		tp.path()!
	}

	return target_path.path_relative(source_path.path)!
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
