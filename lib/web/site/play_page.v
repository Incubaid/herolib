module site

import freeflowuniverse.herolib.core.playbook { PlayBook }

// plays the sections & pages
fn play_pages(mut plbook PlayBook, mut site Site) ! {
	// mut siteconfig := &site.siteconfig

	// if only 1 doctree is specified, then we use that as the default doctree name
	mut doctreename := 'main'
	if plbook.exists(filter: 'site.doctree') {
		if plbook.exists_once(filter: 'site.doctree') {
			mut action := plbook.get(filter: 'site.doctree')!
			mut p := action.params
			doctreename = p.get('name') or { return error('need to specify name in site.doctree') }
		} else {
			return error("can't have more than one site.doctree")
		}
	}

	// LETS FIRST DO THE CATEGORIES
	mut category_actions := plbook.find(filter: 'site.page_category')!
	mut section := Section{}
	for mut action in category_actions {
		// println(action)
		mut p := action.params
		section.position = p.get_int_default('position', 20)!
		section.label = p.get('label') or {
			return error('need to specify label in site.page_category')
		}
		section.path = p.get('path') or {
			return error('need to specify path in site.page_category')
		}
		site.sections << section
		action.done = true // Mark the action as done
	}

	mut page_actions := plbook.find(filter: 'site.page')!
	mut mypage := Page{
		src:  ''
		path: ''
	}
	mut position_next := 1
	mut position := 0
	mut path := ''
	for mut action in page_actions {
		// println(action)
		mut p := action.params
		pathnew := p.get_default('path', '')!
		if pathnew != '' {
			mypage.path = path
			if pathnew.ends_with('.md') {
				// means we fully specified the name
				mypage.path = pathnew
			} else {
				// only remember path if no .md file specified
				path = pathnew
				if !path.ends_with('/') {
					path += '/'
				}
				// println(' -- NEW PATH: ${path}')
				mypage.path = path
			}
		} else {
			mypage.path = path
		}
		position = p.get_int_default('position', 0)!
		if position == 0 {
			position = position_next
			position_next += 1
		} else {
			if position > position_next {
				position_next = position + 1
			}
		}
		mypage.position = position
		mypage.src = p.get('src') or { return error('need to specify src in site.page') }
		mypage.title = p.get_default('title', '')!
		mypage.description = p.get_default('description', '')!
		mypage.slug = p.get_default('slug', '')!
		mypage.draft = p.get_default_false('draft')
		mypage.hide_title = p.get_default_false('hide_title')
		mypage.title_nr = p.get_int_default('title_nr', 0)!

		site.pages << mypage

		action.done = true // Mark the action as done
	}
}
