module core

import incubaid.herolib.core.pathlib
import incubaid.herolib.web.doctree as doctreetools

@[heap]
pub struct Page {
pub mut:
	name            string
	path            string // in collection
	collection_name string
	links           []Link
	// macros          []Macro
	title string
	description string
	questions []Question
	collection &Collection @[skip; str: skip] // Reference to parent collection
}

pub struct Question {
pub mut:
	question string
	answer   string
}

@[params]
pub struct NewPageArgs {
pub:
	name            string      @[required]
	path            string      @[required]
	collection_name string      @[required]
	collection      &Collection @[required]
}

// Read content without processing includes
pub fn (mut p Page) path() !pathlib.Path {
	curpath := p.collection.path()!
	return pathlib.get_file(path: '${curpath.path}/${p.path}', create: false)! // should be relative to collection
}

// Read content with includes processed (default behavior)
@[params]
pub struct ReadContentArgs {
pub mut:
	include bool
}

// Read content can be with or without processing includes
pub fn (mut p Page) content(args ReadContentArgs) !string {
	mut mypath := p.path()!
	mut content := mypath.read()!
	if args.include {
		mut v := map[string]bool{}
		content = p.process_includes(content, mut v)!
	}
	return content
}

// Recursively process includes
fn (mut p Page) process_includes(content string, mut visited map[string]bool) !string {
	mut doctree := p.collection.doctree
	// Prevent circular includes
	page_key := p.key()
	if page_key in visited {
		p.collection.error(
			category:     .circular_include
			page_key:     page_key
			message:      'Circular include detected for page `${page_key}`'
			show_console: false // Don't show immediately, collect for later
		)
		return ''
	}
	visited[page_key] = true

	mut result := content
	mut lines := result.split_into_lines()
	mut processed_lines := []string{}

	for line in lines {
		trimmed := line.trim_space()

		// Check for include action: !!include collection:page or !!include page
		if trimmed.starts_with('!!include') {
			// Parse the include reference
			include_ref := trimmed.trim_string_left('!!include').trim_space()

			// Determine collection and page name
			mut target_collection := p.collection_name
			mut target_page := ''

			if include_ref.contains(':') {
				target_collection, target_page = doctreetools.key_parse(include_ref)!
			} else {
				target_page = doctreetools.name_fix(include_ref)
			}

			// Build page key
			page_ref := '${target_collection}:${target_page}'

			// Get the referenced page from doctree
			mut include_page := doctree.page_get(page_ref) or {
				p.collection.error(
					category:     .missing_include
					page_key:     page_key
					message:      'Included page `${page_ref}` not found'
					show_console: false
				)
				processed_lines << '<!-- Include not found: ${page_ref} -->'
				continue
			}

			// Recursively process the included page
			include_content := include_page.process_includes(include_page.content()!, mut
				visited)!

			processed_lines << include_content
		} else {
			processed_lines << line
		}
	}

	// Remove this page from visited map to allow it to be included again in other contexts
	// This prevents false positives when a page is included multiple times (which is valid)
	visited.delete(page_key)

	return processed_lines.join_lines()
}

pub fn (p Page) key() string {
	return '${p.collection_name}:${p.name}'
}
