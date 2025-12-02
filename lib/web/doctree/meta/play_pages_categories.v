module meta

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.web.doctree as doctreetools
import incubaid.herolib.ui.console

// ============================================================
// PAGES & CATEGORIES: Process pages and build navigation structure
// ============================================================
fn play_pages(mut plbook PlayBook, mut website Site) ! {
	mut collection_current := ''
	mut category_current := &website.root // start at root category, this is basically the navigation tree root

	// ============================================================
	// PASS 1: Process all page_category and page actions
	// ============================================================
	mut all_actions := plbook.find(filter: 'site.')!

	for mut action in all_actions {
		if action.done {
			continue
		}

		// Skip actions that are not page or page_category
		if action.name != 'page_category' && action.name != 'page' {
			continue
		}

		// ========== PAGE CATEGORY ==========
		if action.name == 'page_category' {
			mut p := action.params

			category_path := p.get_default('path', '')!
			if category_path.len == 0 {
				return error('!!site.page_category: must specify "path"')
			}

			// Navigate/create category structure
			category_current = category_current.category_get(category_path)!
			category_current.collapsible = p.get_default_true('collapsible')
			category_current.collapsed = p.get_default_false('collapsed')

			console.print_item('Created page category: "${category_current.path}"')

			action.done = true
			println(category_current)

			// $dbg();
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
				page_collection, page_name = doctreetools.key_parse(page_src)!
			} else {
				// Use previously specified collection if available
				if collection_current.len > 0 {
					page_collection = collection_current
					page_name = doctreetools.name_fix(page_src)
				} else {
					return error('!!site.page: must specify source as "collection:page_name" in "src".\nGot src="${page_src}" with no collection previously set.\nEither specify "collection:page_name" or define a collection first.')
				}
			}

			// Validation
			if page_name.len == 0 {
				return error('!!site.page: could not extract valid page name from src="${page_src}"')
			}
			if page_collection.len == 0 {
				return error('!!site.page: could not determine collection')
			}

			// Store collection for subsequent pages
			collection_current = page_collection

			// Get optional page metadata
			mut page_label := p.get_default('label', '')! // CHANGED: added mut
			if page_label.len == 0 {
				page_label = p.get_default('title', '')!
			}

			page_title := p.get_default('title', '')!
			page_description := p.get_default('description', '')!

			// Create page object
			mut page := Page{
				src:         '${page_collection}:${page_name}'
				label:       page_label
				title:       page_title
				description: page_description
				draft:       p.get_default_false('draft')
				hide_title:  p.get_default_false('hide_title')
				hide:        p.get_default_false('hide')
				nav_path:    category_current.path
			}

			// Add page to current category
			category_current.items << page

			console.print_item('Added page: "${page.src}" (label: "${page.label}")')

			action.done = true
			continue
		}
	}

	console.print_green('Pages and categories processing complete')
}
