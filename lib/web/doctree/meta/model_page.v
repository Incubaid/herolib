module meta

import incubaid.herolib.web.doctree.client as doctree_client
import incubaid.herolib.data.markdown.tools as markdowntools

// Page represents a single documentation page
pub struct Page {
pub mut:
	id          string // Unique identifier: "collection:page_name"
	title       string // Display title (optional, extracted from markdown if empty)
	description string // Brief description for metadata
	questions   []Question
}

pub struct Question {
pub mut:
	question string
	answer   string
}

pub fn (mut p Page) content(client doctree_client.DocTreeClient) !string {
	mut c := client.get_page_content(p.id)!

	if p.title == '' {
		p.title = markdowntools.extract_title(c)
	}
	// TODO in future should do AI
	if p.description == '' {
		p.description = p.title
	}
	return c
}
