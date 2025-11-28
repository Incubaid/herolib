module site

import json

// Top-level config
pub struct NavConfig {
pub mut:
	mySidebar []NavItem
	// myTopbar []NavItem //not used yet
	// myFooter []NavItem //not used yet
}

// -------- Variant Type --------
pub type NavItem = NavDoc | NavCat | NavLink

// --------- DOC ITEM ----------
pub struct NavDoc {
pub:
	id     string //is the page id
	label  string
}

// --------- CATEGORY ----------
pub struct NavCat {
pub mut:
	label       string
	collapsible bool
	collapsed   bool
	items       []NavItem
}

// --------- LINK ----------
pub struct NavLink {
pub:
	label        string
	href         string
	description  string
}

// -------- JSON SERIALIZATION --------

// NavItemJson is used for JSON export with type discrimination
pub struct NavItemJson {
pub mut:
	type_field  string         @[json: 'type']
	// For doc
	id          string         @[omitempty]
	label       string         @[omitempty]
	// For link
	href        string         @[omitempty]
	description string         @[omitempty]
	// For category
	collapsible bool
	collapsed   bool
	items       []NavItemJson  @[omitempty]
}

// Convert a single NavItem to JSON-serializable format
fn nav_item_to_json(item NavItem) !NavItemJson {
	return match item {
		NavDoc {
			NavItemJson{
				type_field: 'doc'
				id:         item.id
				label:      item.label
				collapsible: false
				collapsed:   false
			}
		}
		NavLink {
			NavItemJson{
				type_field:  'link'
				label:       item.label
				href:        item.href
				description: item.description
				collapsible: false
				collapsed:   false
			}
		}
		NavCat {
			mut json_items := []NavItemJson{}
			for sub_item in item.items {
				json_items << nav_item_to_json(sub_item)!
			}
			NavItemJson{
				type_field:  'category'
				label:       item.label
				collapsible: item.collapsible
				collapsed:   item.collapsed
				items:       json_items
			}
		}
	}
}

// Convert entire NavConfig sidebar to JSON-serializable array
fn (nc NavConfig) sidebar_to_json() ![]NavItemJson {
	mut result := []NavItemJson{}
	for item in nc.mySidebar {
		result << nav_item_to_json(item)!
	}
	return result
}



// // Convert entire NavConfig topbar to JSON-serializable array
// fn (nc NavConfig) topbar_to_json() ![]NavItemJson {
// 	mut result := []NavItemJson{}
// 	for item in nc.myTopbar {
// 		result << nav_item_to_json(item)!
// 	}
// 	return result
// }

// // Convert entire NavConfig footer to JSON-serializable array
// fn (nc NavConfig) footer_to_json() ![]NavItemJson {
// 	mut result := []NavItemJson{}
// 	for item in nc.myFooter {
// 		result << nav_item_to_json(item)!
// 	}
// 	return result
// }

port topbar as formatted JSON string
// pub fn (nc NavConfig) jsondump_topbar() !string {
// 	items := nc.topbar_to_json()!
// 	return json.encode_pretty(items)
// }

// // Export footer as formatted JSON string
// pub fn (nc NavConfig) jsondump_footer() !string {
// 	items := nc.footer_to_json()!
// 	return json.encode_pretty(items)
// }

// // Export all navigation as object with sidebar, topbar, footer
// pub fn (nc NavConfig) jsondump_all() !string {
// 	all_nav := map[string][]NavItemJson{
// 		'sidebar': nc.sidebar_to_json()!
// 		'topbar':  nc.topbar_to_json()!
// 		'footer':  nc.footer_to_json()!
// 	}
// 	return json.encode_pretty(all_nav)
// }
