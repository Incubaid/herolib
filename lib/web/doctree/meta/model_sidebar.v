module meta

import json

// ============================================================================
// Sidebar Navigation Models (Domain Types)
// ============================================================================

pub struct SideBar {
pub mut:
	my_sidebar []NavItem
}

pub type NavItem = NavDoc | NavCat | NavLink

pub struct NavDoc {
pub:
	id    string
	label string
	hide_title bool
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
