module meta

import os
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.core.texttools
import time
import incubaid.herolib.ui.console

// ============================================================
// NAVBAR: Process navigation menu
// ============================================================
fn play_navbar(mut plbook PlayBook, mut config SiteConfig) ! {
	// Try 'site.navbar' first, then fallback to deprecated 'site.menu'
	mut navbar_actions := plbook.find(filter: 'site.navbar')!
	if navbar_actions.len == 0 {
		navbar_actions = plbook.find(filter: 'site.menu')!
	}

	// Configure navbar metadata
	if navbar_actions.len > 0 {
		for mut action in navbar_actions {
			mut p := action.params
			config.menu.title = p.get_default('title', config.title)!
			config.menu.logo_alt = p.get_default('logo_alt', '')!
			config.menu.logo_src = p.get_default('logo_src', '')!
			config.menu.logo_src_dark = p.get_default('logo_src_dark', '')!
			action.done = true
		}
	}

	// Process navbar items
	mut navbar_item_actions := plbook.find(filter: 'site.navbar_item')!
	if navbar_item_actions.len == 0 {
		navbar_item_actions = plbook.find(filter: 'site.menu_item')!
	}

	// Clear existing items to prevent duplication
	config.menu.items = []MenuItem{}

	for mut action in navbar_item_actions {
		mut p := action.params

		label := p.get('label') or { return error('!!site.navbar_item: must specify "label"') }

		mut item := MenuItem{
			label:    label
			href:     p.get_default('href', '')!
			to:       p.get_default('to', '')!
			position: p.get_default('position', 'right')!
		}

		// Validate that at least href or to is specified
		if item.href.len == 0 && item.to.len == 0 {
			return error('!!site.navbar_item: must specify either "href" or "to" for label "${label}"')
		}

		config.menu.items << item
		action.done = true
	}
}
