module data

import incubaid.herolib.core.texttools
import incubaid.herolib.core.base
import incubaid.herolib.data.markdown.elements
import incubaid.herolib.data.doctree.pointer

// Note: doc should not get reparsed after invoking this method
pub fn (page Page) process_links(paths map[string]string) ![]string {
	mut not_found := map[string]bool{}
	mut doc := page.doc_immute()!
	for mut element in doc.children_recursive() {
		if mut element is elements.Link {
			if element.cat == .html || (element.cat == .anchor && element.url == '') {
				// is external link or same page anchor, nothing to process
				// maybe in the future check if exists
				continue
			}
			mut name := texttools.name_fix_keepext(element.filename)
			mut site := texttools.name_fix(element.site)
			if site == '' {
				site = page.collection_name
			}
			pointerstr := '${site}:${name}'

			ptr := pointer.pointer_new(text: pointerstr, collection: page.collection_name)!
			mut path := paths[ptr.str()] or {
				not_found[ptr.str()] = true
				continue
			}

			if ptr.cat == .page && ptr.str() !in doc.linked_pages {
				doc.linked_pages << ptr.str()
			}

			// Check if Docusaurus-specific paths are available in Redis
			mut context := base.context() or { base.context_new()! }
			mut redis := context.redis() or { panic('Redis not available') }

			// Try to get Docusaurus-specific path from Redis
			if docusaurus_path := redis.hget('doctree_docusaurus_paths', ptr.str()) {
				// Only use the Docusaurus path if it's not empty
				if docusaurus_path.trim_space() != '' {
					// Use Docusaurus path (already without .md extension)
					// Ensure it starts with / for absolute path
					if docusaurus_path.starts_with('/') {
						path = docusaurus_path
					} else {
						path = '/' + docusaurus_path
					}
				} else {
					// Empty Docusaurus path, fall back to default behavior
					// Fall back to default behavior: relative paths with .md
					if ptr.collection == page.collection_name {
						// same directory
						path = './' + path.all_after_first('/')
					} else {
						path = '../${path}'
					}
				}
			} else {
				// Fall back to default behavior: relative paths with .md
				if ptr.collection == page.collection_name {
					// same directory
					path = './' + path.all_after_first('/')
				} else {
					path = '../${path}'
				}
			}

			if ptr.cat == .image && element.extra.trim_space() != '' {
				path += ' ${element.extra.trim_space()}'
			}

			mut out := '[${element.description}](${path})'
			if ptr.cat == .image {
				out = '!${out}'
			}

			element.content = out
			element.processed = false
			element.state = .linkprocessed
			element.process()!
		}
	}

	return not_found.keys()
}
