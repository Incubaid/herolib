module doctree

import incubaid.herolib.ui.console

// list_pages returns a map of collection names to a list of page names within that collection.
// The structure is map[collectionname][]pagename.
pub fn (mut t Tree) list_pages() map[string][]string {
	mut result := map[string][]string{}
	mut sorted_collections := t.collections.values()
	sorted_collections.sort(a.name < b.name)

	for _, col in sorted_collections {
		mut page_names := []string{}
		mut sorted_pages := col.pages.values()
		sorted_pages.sort(a.name < b.name)
		for _, page in sorted_pages {
			page_names << page.name
		}
		result[col.name] = page_names
	}
	return result
}

// list_markdown returns the collections and their pages in markdown format.
pub fn (mut t Tree) list_markdown() string {
	mut markdown_output := ''
	pages_map := t.list_pages()

	if pages_map.len == 0 {
		return 'No collections or pages found in this doctree.'
	}

	for col_name, page_names in pages_map {
		markdown_output += '## ${col_name}\n'
		if page_names.len == 0 {
			markdown_output += '  * No pages in this collection.\n'
		} else {
			for page_name in page_names {
				markdown_output += '  * ${page_name}\n'
			}
		}
		markdown_output += '\n' // Add a newline for spacing between collections
	}
	return markdown_output
}

// print_pages prints the collections and their pages in a nice, easy-to-see format.
pub fn (mut t Tree) print_pages() {
	pages_map := t.list_pages()
	console.print_header('Doctree: ${t.name}')
	if pages_map.len == 0 {
		console.print_green('No collections or pages found in this doctree.')
		return
	}
	for col_name, page_names in pages_map {
		console.print_green('Collection: ${col_name}')
		if page_names.len == 0 {
			console.print_green('  No pages in this collection.')
		} else {
			for page_name in page_names {
				console.print_item('  ${page_name}')
			}
		}
	}
}
