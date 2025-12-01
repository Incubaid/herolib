module site

// Page represents a single documentation page
pub struct Page {
pub mut:
	id          string // Unique identifier: "collection:page_name"
	title       string // Display title (optional, extracted from markdown if empty)
	description string // Brief description for metadata
	draft       bool   // Mark as draft (hidden from navigation)
	hide_title  bool   // Hide the title when rendering
	src         string // Source reference (same as id in this format)
}
