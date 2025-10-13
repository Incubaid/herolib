module docusaurus

import incubaid.herolib.core.base
import incubaid.herolib.core.texttools

// Store the Docusaurus site structure in Redis for link processing
// This maps collection:page to their actual Docusaurus paths
pub fn (mut docsite DocSite) store_site_structure() ! {
	mut context := base.context()!
	mut redis := context.redis()!

	// Store mapping of collection:page to docusaurus path (without .md extension)
	for page in docsite.website.pages {
		parts := page.src.split(':')
		if parts.len != 2 {
			continue
		}
		collection_name := texttools.name_fix(parts[0])
		page_name := texttools.name_fix(parts[1])

		// Calculate the docusaurus path (without .md extension for URLs)
		mut doc_path := page.path

		// Handle empty or root path
		if doc_path.trim_space() == '' || doc_path == '/' {
			doc_path = page_name
		} else if doc_path.ends_with('/') {
			doc_path += page_name
		}

		// Remove .md extension if present for URL paths
		if doc_path.ends_with('.md') {
			doc_path = doc_path[..doc_path.len - 3]
		}

		// Store in Redis with key format: collection:page.md
		key := '${collection_name}:${page_name}.md'
		redis.hset('doctree_docusaurus_paths', key, doc_path)!
	}
}
