module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.texttools
import incubaid.herolib.data.atlas.collection_error { CollectionError, CollectionErrorCategory }

@[heap]
pub struct Page {
pub mut:
	name            string
	path            pathlib.Path
	collection_name string
	collection      &Collection @[skip; str: skip] // Reference to parent collection
}

@[params]
pub struct NewPageArgs {
pub:
	name            string       @[required]
	path            pathlib.Path @[required]
	collection_name string       @[required]
	collection      &Collection  @[required]
}

pub fn new_page(args NewPageArgs) !Page {
	return Page{
		name:            args.name
		path:            args.path
		collection_name: args.collection_name
		collection:      args.collection
	}
}

// Read content without processing includes
pub fn (mut p Page) read_content() !string {
	return p.path.read()!
}

// Read content with includes processed (default behavior)
@[params]
pub struct ReadContentArgs {
pub mut:
	include bool = true
}

pub fn (mut p Page) content(args ReadContentArgs) !string {
	mut content := p.path.read()!

	if args.include {
		mut v := map[string]bool{}
		return p.process_includes(content, mut v)!
	}
	return content
}

// Recursively process includes
fn (mut p Page) process_includes(content string, mut visited map[string]bool) !string {
	mut atlas := p.collection.atlas
	// Prevent circular includes
	page_key := p.key()
	if page_key in visited {
		p.collection.errors << CollectionError{
			page_key: page_key
			message:  'Circular include detected for page `${page_key}`.'
			category: .circular_include
		}
		return '' // Return empty string for circular includes
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
				parts := include_ref.split(':')
				if parts.len == 2 {
					target_collection = texttools.name_fix(parts[0])
					target_page = texttools.name_fix(parts[1])
				} else {
					p.collection.errors << CollectionError{
						page_key: page_key
						message:  'Invalid include format: `${include_ref}`.'
						category: .include_syntax_error
					}
					processed_lines << '<!-- Invalid include format: ${include_ref} -->'
					continue
				}
			} else {
				target_page = texttools.name_fix(include_ref)
			}

			// Remove .md extension if present
			if target_page.ends_with('.md') {
				target_page = target_page[0..target_page.len - 3]
			}

			// Build page key
			page_ref := '${target_collection}:${target_page}'

			// Get the referenced page from atlas
			mut include_page := atlas.page_get(page_ref) or {
				p.collection.errors << CollectionError{
					page_key: page_key
					message:  'Included page `${page_ref}` not found.'
					category: .missing_include
				}
				// If page not found, keep original line as comment
				processed_lines << '<!-- Include not found: ${page_ref} -->'
				continue
			}

			// Recursively process the included page
			include_content := include_page.process_includes(include_page.read_content()!, mut
				visited)!

			processed_lines << include_content
		} else {
			processed_lines << line
		}
	}

	return processed_lines.join_lines()
}

pub fn (p Page) key() string {
	return '${p.collection_name}:${p.name}'
}
