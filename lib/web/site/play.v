module site

import os
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.core.texttools
import time

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'site.') {
		return
	}

	mut config_action := plbook.ensure_once(filter: 'site.config')!

	mut p := config_action.params
	name := p.get_default('name', 'default')! // Use 'default' as fallback name

	// configure the website
	mut website := new(name: name)!
	mut config := &website.siteconfig

	config.name = texttools.name_fix(name)
	config.title = p.get_default('title', 'Documentation Site')!
	config.description = p.get_default('description', 'Comprehensive documentation built with Docusaurus.')!
	config.tagline = p.get_default('tagline', 'Your awesome documentation')!
	config.favicon = p.get_default('favicon', 'img/favicon.png')!
	config.image = p.get_default('image', 'img/tf_graph.png')!
	config.copyright = p.get_default('copyright', '© ' + time.now().year.str() +
		' Example Organization')!
	config.url = p.get_default('url', '')!
	config.base_url = p.get_default('base_url', '/')!
	config.url_home = p.get_default('url_home', '')!

	// Process !!site.config_meta for specific metadata overrides
	mut meta_action := plbook.ensure_once(filter: 'site.config_meta')!
	mut p_meta := meta_action.params

	// If 'title' is present in site.config_meta, it overrides. Otherwise, meta_title remains empty or uses site.config.title logic in docusaurus model.
	config.meta_title = p_meta.get_default('title', config.title)!
	// If 'image' is present in site.config_meta, it overrides. Otherwise, meta_image remains empty or uses site.config.image logic.
	config.meta_image = p_meta.get_default('image', config.image)!
	// If 'description' is present in site.config_meta, it overrides the main description
	if p_meta.exists('description') {
		config.description = p_meta.get('description')!
	}

	config_action.done = true // Mark the action as done
	meta_action.done = true

	play_import(mut plbook, mut config)!
	play_menu(mut plbook, mut config)!
	play_footer(mut plbook, mut config)!
	play_publish(mut plbook, mut config)!
	play_publish_dev(mut plbook, mut config)!
	play_pages(mut plbook, mut website)!
}

fn play_import(mut plbook PlayBook, mut config SiteConfig) ! {
	mut import_actions := plbook.find(filter: 'site.import')!
	// println('import_actions: ${import_actions}')

	for mut action in import_actions {
		mut p := action.params
		mut replace_map := map[string]string{}
		if replace_str := p.get_default('replace', '') {
			parts := replace_str.split(',')
			for part in parts {
				kv := part.split(':')
				if kv.len == 2 {
					replace_map[kv[0].trim_space()] = kv[1].trim_space()
				}
			}
		}

		mut importpath := p.get_default('path', '')!
		if importpath != '' {
			if !importpath.starts_with('/') {
				importpath = os.abs_path('${plbook.path}/${importpath}')
			}
		}

		mut import_ := ImportItem{
			name:    p.get_default('name', '')!
			url:     p.get_default('url', '')!
			path:    importpath
			dest:    p.get_default('dest', '')!
			replace: replace_map
			visible: p.get_default_false('visible')
		}
		config.imports << import_

		action.done = true // Mark the action as done
	}
}

fn play_menu(mut plbook PlayBook, mut config SiteConfig) ! {
	mut navbar_actions := plbook.find(filter: 'site.navbar')!
	if navbar_actions.len > 0 {
		for mut action in navbar_actions { // Should ideally be one, but loop for safety
			mut p := action.params
			config.menu.title = p.get_default('title', config.title)! // Use existing config.title as ultimate fallback
			config.menu.logo_alt = p.get_default('logo_alt', '')!
			config.menu.logo_src = p.get_default('logo_src', '')!
			config.menu.logo_src_dark = p.get_default('logo_src_dark', '')!
			action.done = true // Mark the action as done
		}
	} else {
		// Fallback to site.menu for title if site.navbar is not found
		mut menu_actions := plbook.find(filter: 'site.menu')!
		for mut action in menu_actions {
			mut p := action.params
			config.menu.title = p.get_default('title', config.title)!
			config.menu.logo_alt = p.get_default('logo_alt', '')!
			config.menu.logo_src = p.get_default('logo_src', '')!
			config.menu.logo_src_dark = p.get_default('logo_src_dark', '')!
			action.done = true // Mark the action as done
		}
	}

	mut menu_item_actions := plbook.find(filter: 'site.navbar_item')!
	if menu_item_actions.len == 0 {
		// Fallback to site.menu_item if site.navbar_item is not found
		menu_item_actions = plbook.find(filter: 'site.menu_item')!
	}

	// Clear existing menu items to prevent duplication
	config.menu.items = []MenuItem{}

	for mut action in menu_item_actions {
		mut p := action.params
		mut item := MenuItem{
			label:    p.get_default('label', 'Documentation')!
			href:     p.get_default('href', '')!
			to:       p.get_default('to', '')!
			position: p.get_default('position', 'right')!
		}
		config.menu.items << item
		action.done = true // Mark the action as done
	}
}

fn play_footer(mut plbook PlayBook, mut config SiteConfig) ! {
	mut footer_actions := plbook.find(filter: 'site.footer')!
	for mut action in footer_actions {
		mut p := action.params
		config.footer.style = p.get_default('style', 'dark')!
		action.done = true // Mark the action as done
	}

	mut footer_item_actions := plbook.find(filter: 'site.footer_item')!
	mut links_map := map[string][]FooterItem{}

	// Clear existing footer links to prevent duplication
	config.footer.links = []FooterLink{}

	for mut action in footer_item_actions {
		mut p := action.params
		title := p.get_default('title', 'Docs')!
		mut item := FooterItem{
			label: p.get_default('label', 'Introduction')!
			href:  p.get_default('href', '')!
			to:    p.get_default('to', '')!
		}

		if title !in links_map {
			links_map[title] = []FooterItem{}
		}
		links_map[title] << item
		action.done = true // Mark the action as done
	}

	// Convert map to footer links array
	for title, items in links_map {
		config.footer.links << FooterLink{
			title: title
			items: items
		}
	}
}

fn play_publish(mut plbook PlayBook, mut config SiteConfig) ! {
	mut build_dest_actions := plbook.find(filter: 'site.publish')!
	for mut action in build_dest_actions {
		mut p := action.params
		mut dest := BuildDest{
			path:     p.get_default('path', '')! // can be url
			ssh_name: p.get_default('ssh_name', '')!
		}
		config.build_dest << dest
		action.done = true // Mark the action as done
	}
}

fn play_publish_dev(mut plbook PlayBook, mut config SiteConfig) ! {
	mut build_dest_actions := plbook.find(filter: 'site.publish_dev')!
	for mut action in build_dest_actions {
		mut p := action.params
		mut dest := BuildDest{
			path:     p.get_default('path', '')! // can be url
			ssh_name: p.get_default('ssh_name', '')!
		}
		config.build_dest_dev << dest
		action.done = true // Mark the action as done
	}
}
