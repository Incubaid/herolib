module meta

@[heap]
pub struct Site {
pub mut:
	doctree_path   string     // path to the export of the doctree site
	config         SiteConfig // Full site configuration
	pages          []Page
	links          []Link
	categories     []Category
	announcements  []Announcement // there can be more than 1 announcement
	imports        []ImportItem
	build_dest     []BuildDest // Production build destinations (from !!site.build_dest)
	build_dest_dev []BuildDest // Development build destinations (from !!site.build_dest_dev)
}

pub fn (mut s Site) sidebar() SideBar {
	mut result := SideBar{
		my_sidebar: []NavItem{}
	}

	// If no pages, return empty sidebar
	if s.pages.len == 0 {
		return result
	}

	// Build a map of category_id -> pages for efficient lookup
	mut category_pages := map[int][]Page{}
	mut uncategorized_pages := []Page{}

	// Group pages by category
	for page in s.pages {
		if page.category_id == 0 {
			// Page at root level (no category)
			uncategorized_pages << page
		} else {
			// Page belongs to a category
			if page.category_id !in category_pages {
				category_pages[page.category_id] = []Page{}
			}
			category_pages[page.category_id] << page
		}
	}

	// Sort pages within each category by their order in the pages array
	for category_id in category_pages.keys() {
		category_pages[category_id].sort(a.src < b.src)
	}

	// Sort uncategorized pages
	uncategorized_pages.sort(a.src < b.src)

	// ============================================================
	// Build nested category structure from path
	// ============================================================
	mut category_tree := map[string]&NavCat{}

	// PASS 1: Create all category nodes (even empty intermediate ones)
	for i, category in s.categories {
		category_id := i + 1 // categories are 1-indexed

		// Split path into parts (e.g., "Getting Started/Advanced/Deep" -> ["Getting Started", "Advanced", "Deep"])
		path_parts := if category.path.contains('/') {
			category.path.split('/')
		} else {
			[category.path]
		}

		// Create all nodes in the path hierarchy
		mut current_path := ''

		for part_idx, part in path_parts {
			if current_path.len > 0 {
				current_path += '/'
			}
			current_path += part

			// Check if this node already exists
			if current_path !in category_tree {
				// Create new category node
				mut new_cat := &NavCat{
					label:       part
					collapsible: category.collapsible
					collapsed:   category.collapsed
					items:       []NavItem{}
				}
				category_tree[current_path] = new_cat

				// If this is not the root of the path, add it to its parent
				if part_idx > 0 {
					parent_path := path_parts[0..part_idx].join('/')
					if parent_path in category_tree {
						mut parent_cat := category_tree[parent_path]
						parent_cat.items << new_cat
					}
				}
			}
		}
	}

	// PASS 2: Add pages to their designated categories
	for i, category in s.categories {
		category_id := i + 1 // categories are 1-indexed

		// Skip if no pages in this category
		if category_id !in category_pages {
			continue
		}

		// Build the full path for this category
		full_path := category.path

		// Add pages to this category
		if full_path in category_tree {
			mut leaf_cat := category_tree[full_path]
			for page in category_pages[category_id] {
				if !page.hide {
					// Convert page src format "collection:name" to path "collection/name"
					path := page.src.replace(':', '/')

					nav_doc := NavDoc{
						path:  path
						label: if page.label.len > 0 { page.label } else { page.title }
					}
					leaf_cat.items << nav_doc
				}
			}
		}
	}

	// ============================================================
	// PASS 3: Add root-level categories to sidebar
	// ============================================================
	// Find all root-level categories (those without '/')
	mut added_roots := map[string]bool{}

	for i, category in s.categories {
		// Only process top-level categories
		if !category.path.contains('/') && category.path.len > 0 {
			root_path := category.path
			// Only add each root once
			if root_path !in added_roots {
				if root_path in category_tree {
					result.my_sidebar << category_tree[root_path]
					added_roots[root_path] = true
				}
			}
		}
	}

	// ============================================================
	// PASS 4: Add uncategorized pages at root level
	// ============================================================
	for page in uncategorized_pages {
		if !page.hide {
			// Convert page src format "collection:name" to path "collection/name"
			path := page.src.replace(':', '/')

			nav_doc := NavDoc{
				path:  path
				label: if page.label.len > 0 { page.label } else { page.title }
			}
			result.my_sidebar << nav_doc
		}
	}

	// ============================================================
	// PASS 5: Add standalone links (if needed)
	// ============================================================
	for link in s.links {
		nav_link := NavLink{
			label:       link.label
			href:        link.href
			description: link.description
		}
		result.my_sidebar << nav_link
	}

	return result
}

pub fn (mut s Site) sidebar_str() string {
	mut result := []string{}
	mut sidebar := s.sidebar()

	if sidebar.my_sidebar.len == 0 {
		return 'Sidebar is empty\n'
	}

	result << '📑 SIDEBAR STRUCTURE'
	result << '━'.repeat(60)

	for i, item in sidebar.my_sidebar {
		is_last := i == sidebar.my_sidebar.len - 1
		prefix := if is_last { '└── ' } else { '├── ' }

		match item {
			NavDoc {
				result << '${prefix}📄 ${item.label}'
				result << '    └─ path: ${item.path}'
			}
			NavCat {
				// Category header
				collapse_icon := if item.collapsed { '▶ ' } else { '▼ ' }
				result << '${prefix}${collapse_icon}📁 ${item.label}'

				// Category metadata
				if !item.collapsed {
					result << '    ├─ collapsible: ${item.collapsible}'
					result << '    └─ items: ${item.items.len}'

					// Sub-items
					for j, sub_item in item.items {
						is_last_sub := j == item.items.len - 1
						sub_prefix := if is_last_sub { '    └── ' } else { '    ├── ' }

						match sub_item {
							NavDoc {
								result << '${sub_prefix}📄 ${sub_item.label} [${sub_item.path}]'
							}
							NavCat {
								// Nested categories
								sub_collapse_icon := if sub_item.collapsed { '▶ ' } else { '▼ ' }
								result << '${sub_prefix}${sub_collapse_icon}📁 ${sub_item.label}'
							}
							NavLink {
								result << '${sub_prefix}🔗 ${sub_item.label}'
								if sub_item.description.len > 0 {
									result << '         └─ ${sub_item.description}'
								}
							}
						}
					}
				}
			}
			NavLink {
				result << '${prefix}🔗 ${item.label}'
				result << '    └─ href: ${item.href}'
				if item.description.len > 0 {
					result << '    └─ desc: ${item.description}'
				}
			}
		}

		// Add spacing between root items
		if i < sidebar.my_sidebar.len - 1 {
			result << ''
		}
	}

	result << '━'.repeat(60)
	result << '📊 SUMMARY'
	result << '  Total items: ${sidebar.my_sidebar.len}'
	result << '  Pages: ${s.pages.len}'
	result << '  Categories: ${s.categories.len}'
	result << '  Links: ${s.links.len}'

	return result.join('\n') + '\n'
}
