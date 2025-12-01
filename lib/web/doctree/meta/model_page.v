module meta

import incubaid.herolib.web.doctree.client as doctree_client


// Page represents a single documentation page
pub struct Page {
pub mut:
	id          string // Unique identifier: "collection:page_name"
	title       string // Display title (optional, extracted from markdown if empty)
	description string // Brief description for metadata
}


