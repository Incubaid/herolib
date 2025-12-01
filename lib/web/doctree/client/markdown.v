module client

// list_markdown returns the collections and their pages in markdown format.
pub fn (mut c AtlasClient) list_markdown() !string {
	mut markdown_output := ''
	pages_map := c.list_pages_map()!

	if pages_map.len == 0 {
		return 'No collections or pages found in this doctree export.'
	}

	mut sorted_collections := pages_map.keys()
	sorted_collections.sort()

	for col_name in sorted_collections {
		page_names := pages_map[col_name]
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
