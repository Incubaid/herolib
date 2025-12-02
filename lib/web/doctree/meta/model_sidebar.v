module meta

// ============================================================================
// Sidebar Navigation Models (Domain Types)
// is the result of walking through the pages, links and categories to build the sidebar structure
// ============================================================================

pub struct SideBar {
pub mut:
	my_sidebar []NavItem
}

pub type NavItem = NavDoc | NavCat | NavLink

pub struct NavDoc {
pub:
	path  string // path is $collection/$name without .md, this is a subdir of the doctree export dir
	label string
}

pub struct NavCat {
pub mut:
	label       string
	collapsible bool = true
	collapsed   bool
	items       []NavItem
}

pub struct NavLink {
pub:
	label       string
	href        string
	description string
}
