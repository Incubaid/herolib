module atlas

import incubaid.herolib.core.texttools
import incubaid.herolib.ui.console

pub enum LinkFileType {
	page  // Default: link to another page
	file  // Link to a non-image file
	image // Link to an image file
}

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
	file_type              LinkFileType // Type of the link target: file, image, or page (default)
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

// Get the collection:item key for this link
fn (mut self Link) key() string {
	return '${self.target_collection_name}:${self.target_item_name}'
}

// Get the target page this link points to
pub fn (mut self Link) target_page() !&Page {
	if self.status == .external {
		return error('External links do not have a target page')
	}
	return self.page.collection.atlas.page_get(self.key())
}

// Get the target file this link points to
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

			// Determine link type based on content
			mut detected_file_type := LinkFileType.page

			// Check if it's an image link (starts with !)
			if image_open != -1 {
				detected_file_type = .image
			} else if target.contains('.') && !target.trim_space().to_lower().ends_with('.md') {
				// File link: has extension but not .md
				detected_file_type = .file
			}

			// console.print_debug('Found link: text="${text}", target="${target}", type=${detected_file_type}')

			// Store position - use image_open if it's an image, otherwise open_bracket
			link_start_pos := if detected_file_type == .image { image_open } else { open_bracket }

			// For image links, src should include the ! prefix
			link_src := if detected_file_type == .image {
				line[image_open..close_paren + 1]
			} else {
				line[open_bracket..close_paren + 1]
			}

			mut link := Link{
				src:       link_src
				text:      text
				target:    target.trim_space()
				line:      line_idx + 1
				pos:       link_start_pos
				file_type: detected_file_type
				page:      &p
			}

			p.parse_link_target(mut link)!
			// No need to set file_type to false for external links, as it's already .page by default
			links << link

			pos = close_paren + 1
		}
	}
	return links
}

// Parse link target to extract collection and page
fn (mut p Page) parse_link_target(mut link Link) ! {
	mut target := link.target.to_lower().trim_space()

	// Check for external links (http, https, mailto, ftp)
	if target.starts_with('http://') || target.starts_with('https://')
		|| target.starts_with('mailto:') || target.starts_with('ftp://') {
		link.status = .external
		return
	}

	// Check for anchor links
	if target.starts_with('#') {
		link.status = .anchor
		return
	}

	// Handle relative paths - extract the last part after /
	if target.contains('/') {
		parts := target.split('/')
		if parts.len > 1 {
			target = parts[parts.len - 1]
		}
	}

	// Format: $collection:$pagename or $collection:$pagename.md
	if target.contains(':') {
		parts := target.split(':')
		if parts.len >= 2 {
			link.target_collection_name = texttools.name_fix(parts[0])
			// For file links, use name without extension; for page links, normalize normally
			if link.file_type == .file {
				link.target_item_name = texttools.name_fix_no_ext(parts[1])
			} else {
				link.target_item_name = normalize_page_name(parts[1])
			}
		}
	} else {
		// For file links, use name without extension; for page links, normalize normally
		if link.file_type == .file {
			link.target_item_name = texttools.name_fix_no_ext(target).trim_space()
		} else {
			link.target_item_name = normalize_page_name(target).trim_space()
		}
		link.target_collection_name = p.collection.name
	}

	// console.print_debug('Parsed link target: collection="${link.target_collection_name}", item="${link.target_item_name}", type=${link.file_type}')

	// Validate link target exists
	mut target_exists := false
	mut error_category := CollectionErrorCategory.invalid_page_reference
	mut error_prefix := 'Broken link'

	if link.file_type == .file || link.file_type == .image {
		target_exists = p.collection.atlas.file_or_image_exists(link.key())!
		error_category = .invalid_file_reference
		error_prefix = if link.file_type == .file { 'Broken file link' } else { 'Broken image link' }
	} else {
		target_exists = p.collection.atlas.page_exists(link.key())!
	}

	// console.print_debug('Link target exists: ${target_exists} for key=${link.key()}')

	if target_exists {
		link.status = .found
	} else {
		p.collection.error(
			category:     error_category
			page_key:     p.key()
			message:      '${error_prefix} to `${link.key()}` at line ${link.line}: `${link.src}`'
			show_console: true
		)
		link.status = .not_found
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
		is_local := link.target_collection_name == p.collection.name
		if !args.cross_collection && !is_local {
			continue
		}

		// Calculate new link path based on mode
		new_link := if args.export_mode {
			p.export_link_path(mut link) or { continue }
		} else {
			p.filesystem_link_path(mut link) or { continue }
		}

		// Build the complete link markdown
		// For image links, link.src already includes the !, so we build the same format
		prefix := if link.file_type == .image { '!' } else { '' }
		new_link_md := '${prefix}[${link.text}](${new_link})'

		// Replace in content
		content = content.replace(link.src, new_link_md)
	}

	return content
}

// export_link_path calculates path for export (self-contained: all references are local)
fn (mut p Page) export_link_path(mut link Link) !string {
	match link.file_type {
		.image {
			mut tf := link.target_file()!
			return 'img/${tf.file_name()}'
		}
		.file {
			mut tf := link.target_file()!
			return 'files/${tf.file_name()}'
		}
		.page {
			mut tp := link.target_page()!
			return '${tp.name}.md'
		}
	}
}

// filesystem_link_path calculates path using actual filesystem paths
fn (mut p Page) filesystem_link_path(mut link Link) !string {
	source_path := p.path()!

	mut target_path := match link.file_type {
		.image, .file {
			mut tf := link.target_file()!
			tf.path()!
		}
		.page {
			mut tp := link.target_page()!
			tp.path()!
		}
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
