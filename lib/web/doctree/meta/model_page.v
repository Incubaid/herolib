module meta

// Page represents a single documentation page
pub struct Page {
pub mut:
	src         string // Unique identifier: "collection:page_name" marks where the page is from. (is also name_fix'ed)
	label       string // Display label in navigation e.g. "Getting Started"
	title       string // Display title (optional, extracted from markdown if empty)
	description string // Brief description for metadata
	draft       bool   // Is this page a draft? Means only show in development mode
	hide_title  bool   // Should the title be hidden on the page?
	hide        bool   // Should the page be hidden from navigation?
	category_id int    // Optional category ID this page belongs to, if 0 it means its at root level
	nav_path    string // navigation path e.g. "Operations/Daily"
}
