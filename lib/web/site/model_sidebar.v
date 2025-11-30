module site

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

// ============================================================================
// JSON Serialization Struct (unified to avoid sum type _type field)
// ============================================================================

struct SidebarItem {
	typ         string @[json: 'type']
	id          string @[omitempty]
	label       string
	href        string        @[omitempty]
	description string        @[omitempty]
	collapsible bool          @[json: 'collapsible'; omitempty]
	collapsed   bool          @[json: 'collapsed'; omitempty]
	items       []SidebarItem @[omitempty]
}

// ============================================================================
// JSON Serialization
// ============================================================================

pub fn (sb SideBar) sidebar_to_json() !string {
	items := sb.my_sidebar.map(to_sidebar_item(it))
	return json.encode_pretty(items)
}

fn to_sidebar_item(item NavItem) SidebarItem {
	return match item {
		NavDoc { from_doc(item) }
		NavLink { from_link(item) }
		NavCat { from_category(item) }
	}
}

fn from_doc(doc NavDoc) SidebarItem {
	return SidebarItem{
		typ:   'doc'
		id:    extract_page_id(doc.id)
		label: doc.label
	}
}

fn from_link(link NavLink) SidebarItem {
	return SidebarItem{
		typ:         'link'
		label:       link.label
		href:        link.href
		description: link.description
	}
}

fn from_category(cat NavCat) SidebarItem {
	return SidebarItem{
		typ:         'category'
		label:       cat.label
		collapsible: cat.collapsible
		collapsed:   cat.collapsed
		items:       cat.items.map(to_sidebar_item(it))
	}
}

fn extract_page_id(id string) string {
	parts := id.split(':')
	if parts.len == 2 {
		return parts[1]
	}
	return id
}
