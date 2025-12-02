module meta

import os
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.core.texttools
import time
import incubaid.herolib.ui.console

// ============================================================
// FOOTER: Process footer configuration
// ============================================================
fn play_footer(mut plbook PlayBook, mut config SiteConfig) ! {
	// Process footer style (optional)
	mut footer_actions := plbook.find(filter: 'site.footer')!
	for mut action in footer_actions {
		mut p := action.params
		config.footer.style = p.get_default('style', 'dark')!
		action.done = true
	}

	// Process footer items (multiple)
	mut footer_item_actions := plbook.find(filter: 'site.footer_item')!
	mut links_map := map[string][]FooterItem{}

	// Clear existing links to prevent duplication
	config.footer.links = []FooterLink{}

	for mut action in footer_item_actions {
		mut p := action.params

		title := p.get_default('title', 'Docs')!

		label := p.get('label') or {
			return error('!!site.footer_item: must specify "label"')
		}

		mut item := FooterItem{
			label: label
			href:  p.get_default('href', '')!
			to:    p.get_default('to', '')!
		}

		// Validate that href or to is specified
		if item.href.len == 0 && item.to.len == 0 {
			return error('!!site.footer_item for "${label}": must specify either "href" or "to"')
		}

		if title !in links_map {
			links_map[title] = []FooterItem{}
		}
		links_map[title] << item
		action.done = true
	}

	// Convert map to footer links array
	for title, items in links_map {
		config.footer.links << FooterLink{
			title: title
			items: items
		}
	}
}
