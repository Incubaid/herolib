module site

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.core.texttools

// plays the sections & pages
fn play_pages(mut plbook PlayBook, mut site Site) ! {
	// mut siteconfig := &site.siteconfig

	// if only 1 doctree is specified, then we use that as the default doctree name
	// mut doctreename := 'main' // Not used for now, keep commented for future doctree integration
	// if plbook.exists(filter: 'site.doctree') {
	// 	if plbook.exists_once(filter: 'site.doctree') {
	// 		mut action := plbook.get(filter: 'site.doctree')!
	// 		mut p := action.params
	// 		doctreename = p.get('name') or { return error('need to specify name in site.doctree') }
	// 	} else {
	// 		return error("can't have more than one site.doctree")
	// 	}
	// }

	mut section_current := Section{} // is the category
	mut position_section := 1
	mut position_category := 100 // Start categories at position 100
	mut collection_current := '' // current collection we are working on

	mut all_actions := plbook.find(filter: 'site.')!

	for mut action in all_actions {
		if action.done {
			continue
		}

		mut p := action.params

		if action.name == 'page_category' {
			mut section := Section{}
			section.name = p.get('name') or {
				return error('need to specify name in site.page_category. Action: ${action}')
			}
			position_section = 1 // go back to default position for pages in the category
			section.position = p.get_int_default('position', position_category)!
			if section.position == position_category {
				position_category += 100 // Increment for next category
			}
			section.label = p.get_default('label', texttools.name_fix_snake_to_pascal(section.name))!
			section.path = p.get_default('path', texttools.name_fix(section.label))!
			section.description = p.get_default('description', '')!

			site.sections << section
			action.done = true // Mark the action as done
			section_current = section
			continue // next action
		}

		if action.name == 'page' {
			mut pagesrc := p.get_default('src', '')!
			mut pagename := p.get_default('name', '')!
			mut pagecollection := ''

			if pagesrc.contains(':') {
				pagecollection = pagesrc.split(':')[0]
				pagename = pagesrc.split(':')[1]
			} else {
				if collection_current.len > 0 {
					pagecollection = collection_current
					pagename = pagesrc // ADD THIS LINE - use pagesrc as the page name
				} else {
					return error('need to specify collection in page.src path as collection:page_name or make sure someone before you did. Got src="${pagesrc}" with no collection set. Action: ${action}')
				}
			}

			pagecollection = texttools.name_fix(pagecollection)
			collection_current = pagecollection
			pagename = texttools.name_fix_keepext(pagename)
			if pagename.ends_with('.md') {
				pagename = pagename.replace('.md', '')
			}

			if pagename == '' {
				return error('need to specify name in page.src or specify in path as collection:page_name. Action: ${action}')
			}
			if pagecollection == '' {
				return error('need to specify collection in page.src or specify in path as collection:page_name. Action: ${action}')
			}

			// recreate the pagepath
			pagesrc = '${pagecollection}:${pagename}'

			// get sectionname from category, page_category or section, if not specified use current section
			section_name := p.get_default('category', p.get_default('page_category', p.get_default('section',
				section_current.name)!)!)!
			mut pagepath := p.get_default('path', section_current.path)!
			pagepath = pagepath.trim_space().trim('/')
			// Only apply name_fix if it's a simple name (no path separators)
			// For paths like 'appendix/internet_today', preserve the structure
			if !pagepath.contains('/') {
				pagepath = texttools.name_fix(pagepath)
			}
			// Ensure pagepath ends with / to indicate it's a directory path
			if pagepath.len > 0 && !pagepath.ends_with('/') {
				pagepath += '/'
			}

			mut mypage := Page{
				section_name: section_name
				name:         pagename
				path:         pagepath
				src:          pagesrc
			}

			mypage.position = p.get_int_default('position', 0)!
			if mypage.position == 0 {
				mypage.position = section_current.position + position_section
				position_section += 1
			}
			mypage.title = p.get_default('title', '')!

			mypage.description = p.get_default('description', '')!
			mypage.slug = p.get_default('slug', '')!
			mypage.draft = p.get_default_false('draft')
			mypage.hide_title = p.get_default_false('hide_title')
			if mypage.title.len > 0 {
				mypage.hide_title = true
			}
			mypage.title_nr = p.get_int_default('title_nr', 0)!

			site.pages << mypage

			action.done = true // Mark the action as done
		}

		// println(action)
		// println(section_current)
		// println(site.pages.last())
		// $dbg;
	}
}
