module site

import os
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.core.texttools
import time
import incubaid.herolib.ui.console

// ============================================================
// PAGES: Process pages and build navigation structure
// ============================================================
fn play_pages(mut plbook PlayBook, mut website Site) ! {
	mut collection_current := '' // Track current collection for reuse
	mut categories := map[string]CategoryInfo{} // Map of category name -> info
	mut category_current := '' // Track current active category
	mut root_nav_items := []NavItem{} // Root-level items (pages without category)
	mut next_category_position := 100 // Auto-increment position for categories

	// ============================================================
	// PASS 1: Process all page and category actions
	// ============================================================
	mut all_actions := plbook.find(filter: 'site.')!

	for mut action in all_actions {
		if action.done {
			continue
		}

		// ========== PAGE CATEGORY ==========
		if action.name == 'page_category' {
			mut p := action.params

			category_name := p.get('name') or {
				return error('!!site.page_category: must specify "name"')
			}

			category_name = texttools.name_fix(category_name)

			// Get label (derive from name if not specified)
			mut label := p.get_default('label', texttools.name_fix_snake_to_pascal(category_name))!
			mut position := p.get_int_default('position', next_category_position)!

			// Auto-increment position if using default
			if position == next_category_position {
				next_category_position += 100
			}

			// Create and store category info
			categories[category_name] = CategoryInfo{
				name:      category_name
				label:     label
				position:  position
				nav_items: []NavItem{}
			}

			category_current = category_name
			action.done = true
			continue
		}

		// ========== PAGE ==========
		if action.name == 'page' {
			mut p := action.params

			mut page_src := p.get_default('src', '')!
			mut page_collection := ''
			mut page_name := ''

			// Parse collection:page format from src
			if page_src.contains(':') {
				parts := page_src.split(':')
				page_collection = texttools.name_fix(parts[0])
				page_name = texttools.name_fix_keepext(parts[1])
			} else {
				// Use previously specified collection if available
				if collection_current.len > 0 {
					page_collection = collection_current
					page_name = texttools.name_fix_keepext(page_src)
				} else {
					return error('!!site.page: must specify source as "collection:page_name" in "src".\nGot src="${page_src}" with no collection previously set.\nEither specify "collection:page_name" or define a collection first.')
				}
			}

			// Clean up page name (remove .md if present)
			if page_name.ends_with('.md') {
				page_name = page_name[0..page_name.len - 3]
			}
			page_name = texttools.name_fix(page_name)

			// Validation
			if page_name.len == 0 {
				return error('!!site.page: could not extract valid page name from src="${page_src}"')
			}
			if page_collection.len == 0 {
				return error('!!site.page: could not determine collection')
			}

			// Store collection for subsequent pages
			collection_current = page_collection

			// Build page ID
			page_id := '${page_collection}:${page_name}'

			// Get optional page metadata
			page_title := p.get_default('title', '')!
			page_description := p.get_default('description', '')!
			page_draft := p.get_default_false('draft')
			page_hide_title := p.get_default_false('hide_title')

			// Create page
			mut page := Page{
				id:          page_id
				title:       page_title
				description: page_description
				draft:       page_draft
				hide_title:  page_hide_title
				src:         page_id
			}

			website.pages[page_id] = page

			// Create navigation item
			nav_doc := NavDoc{
				id:    page_id
				label: if page_title.len > 0 { page_title } else { page_name }
			}

			// Add to appropriate category or root
			if category_current.len > 0 {
				if category_current in categories {
					mut cat_info := categories[category_current]
					cat_info.nav_items << nav_doc
					categories[category_current] = cat_info
				}
			} else {
				root_nav_items << nav_doc
			}

			action.done = true
			continue
		}
	}
