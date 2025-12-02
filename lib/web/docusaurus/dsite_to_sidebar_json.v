module doc

import incubaid.herolib.web.doctree.meta as site
import json

// this is the logic to create docusaurus sidebar.json from site.NavItems

struct Sidebar {
pub mut:
	items []NavItem
}

type NavItem = NavDoc | NavCat | NavLink

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

pub struct NavDoc {
pub mut:
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
pub mut:
	label       string
	href        string
	description string
}

// ============================================================================
// JSON Serialization
// ============================================================================

pub fn sidebar_to_json(sb site.SideBar) !string {
	items := sb.my_sidebar.map(to_sidebar_item(it))
	return json.encode_pretty(items)
}

fn to_sidebar_item(item site.NavItem) SidebarItem {
	return match item {
		NavDoc { from_doc(item) }
		NavLink { from_link(item) }
		NavCat { from_category(item) }
	}
}

fn from_doc(doc site.NavDoc) SidebarItem {
	return SidebarItem{
		typ:   'doc'
		id:    doc.id
		label: doc.label
	}
}

fn from_link(link site.NavLink) SidebarItem {
	return SidebarItem{
		typ:         'link'
		label:       link.label
		href:        link.href
		description: link.description
	}
}

fn from_category(cat site.NavCat) SidebarItem {
	return SidebarItem{
		typ:         'category'
		label:       cat.label
		collapsible: cat.collapsible
		collapsed:   cat.collapsed
		items:       cat.items.map(to_sidebar_item(it))
	}
}
