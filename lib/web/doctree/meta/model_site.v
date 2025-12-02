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
	eprintln('DEBUG: Grouping ${s.pages.len} pages into categories')
	for page in s.pages {
		if page.category_id == 0 {
			// Page at root level (no category)
			uncategorized_pages << page
			eprintln('  Page "${page.src}": UNCATEGORIZED')
		} else {
			// Page belongs to a category
			if page.category_id !in category_pages {
				category_pages[page.category_id] = []Page{}
			}
			category_pages[page.category_id] << page
			if page.category_id < s.categories.len {
				eprintln('  Page "${page.src}": category_id=${page.category_id} -> "${s.categories[page.category_id].path}"')
			} else {
				eprintln('  Page "${page.src}": category_id=${page.category_id} -> INVALID INDEX!')
			}
		}
	}
	eprintln('DEBUG: Grouped into ${category_pages.len} categories + ${uncategorized_pages.len} uncategorized')

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
	mut parent_map := map[string]string{} // Map of path -> parent_path

	// PASS 1: Create ALL category nodes first
	// Collect all paths first, then sort by depth (shallow first)
	mut all_paths := []string{}
	for i, category in s.categories {
		path_parts := if category.path.contains('/') {
			category.path.split('/')
		} else {
			[category.path]
		}

		mut current_path := ''
		for part_idx, part in path_parts {
			if current_path.len > 0 {
				current_path += '/'
			}
			current_path += part

			// Add this path if not already added
			if current_path !in category_tree {
				all_paths << current_path
			}
		}
	}

	// Sort paths by depth (number of '/') so we create parents before children
	all_paths.sort(a.count('/') < b.count('/'))

	// Now create all nodes in order of depth
	for path in all_paths {
		if path !in category_tree {
			path_parts := path.split('/')
			part := path_parts[path_parts.len - 1]

			// Find the category with this path to get collapsible/collapsed settings
			mut collapsible := true
			mut collapsed := false
			for category in s.categories {
				if category.path == path {
					collapsible = category.collapsible
					collapsed = category.collapsed
					break
				}
			}

			// Create new category node
			mut new_cat := &NavCat{
				label:       part
				collapsible: collapsible
				collapsed:   collapsed
				items:       []NavItem{}
			}
			category_tree[path] = new_cat

			// Record parent for later linking
			if path.contains('/') {
				last_slash := path.last_index('/') or { 0 }
				parent_path := path[0..last_slash]
				parent_map[path] = parent_path
			}
		}
	}

	// PASS 2: Link all parent-child relationships
	// Process these in order of depth to ensure parents are linked first
	mut sorted_paths := parent_map.keys()
	sorted_paths.sort(a.count('/') < b.count('/'))

	for path in sorted_paths {
		parent_path := parent_map[path]
		if parent_path in category_tree && path in category_tree {
			mut parent_cat := category_tree[parent_path]
			child_cat := category_tree[path]

			// Only add if not already added
			mut already_added := false
			for item in parent_cat.items {
				if item is NavCat && item.label == child_cat.label {
					already_added = true
					break
				}
			}
			if !already_added {
				parent_cat.items << child_cat
			}
		}
	}

	// PASS 3: Add pages to their designated categories
	eprintln('DEBUG PASS 3: Adding pages to categories')
	for i, category in s.categories {
		category_id := i // categories are 0-indexed in the page assignment

		// Skip if no pages in this category
		if category_id !in category_pages {
			eprintln('  Category ${category_id} ("${category.path}"): no pages')
			continue
		}

		// Build the full path for this category
		full_path := category.path

		eprintln('  Category ${category_id} ("${full_path}"): ${category_pages[category_id].len} pages')

		// Add pages to this category
		if full_path in category_tree {
			mut leaf_cat := category_tree[full_path]
			for page in category_pages[category_id] {
				if !page.hide {
					// Convert page src format "collection:name" to path "collection/name"
					path := page.src.replace(':', '/')

					eprintln('    Adding page: ${page.src} -> ${path}')

					nav_doc := NavDoc{
						path:  path
						label: if page.label.len > 0 { page.label } else { page.title }
					}
					leaf_cat.items << nav_doc
				}
			}
		} else {
			eprintln('    ERROR: Category path "${full_path}" not in category_tree!')
		}
	}

	// ============================================================
	// PASS 4: Add root-level categories to sidebar
	// ============================================================
	// Find all root-level categories (those without '/') and add them once
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
	// PASS 5: Add uncategorized pages at root level
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
	// PASS 6: Add standalone links (if needed)
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
