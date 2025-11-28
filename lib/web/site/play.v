module site

import os
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.core.texttools
import time
import incubaid.herolib.ui.console

// Main entry point for processing site HeroScript
pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'site.') {
		return
	}

	console.print_header('Processing Site Configuration')

	// ============================================================
	// STEP 1: Initialize core site configuration
	// ============================================================
	console.print_item('Step 1: Loading site configuration')
	mut config_action := plbook.ensure_once(filter: 'site.config')!
	mut p := config_action.params

	name := p.get_default('name', 'default')!
	mut website := new(name: name)!
	mut config := &website.siteconfig

	// Load core configuration
	config.name = texttools.name_fix(name)
	config.title = p.get_default('title', 'Documentation Site')!
	config.description = p.get_default('description', 'Comprehensive documentation built with Docusaurus.')!
	config.tagline = p.get_default('tagline', 'Your awesome documentation')!
	config.favicon = p.get_default('favicon', 'img/favicon.png')!
	config.image = p.get_default('image', 'img/tf_graph.png')!
	config.copyright = p.get_default('copyright', '© ${time.now().year} Example Organization')!
	config.url = p.get_default('url', '')!
	config.base_url = p.get_default('base_url', '/')!
	config.url_home = p.get_default('url_home', '')!

	config_action.done = true

	// ============================================================
	// STEP 2: Apply optional metadata overrides
	// ============================================================
	console.print_item('Step 2: Applying metadata overrides')
	if plbook.exists_once(filter: 'site.config_meta') {
		mut meta_action := plbook.get(filter: 'site.config_meta')!
		mut p_meta := meta_action.params

		config.meta_title = p_meta.get_default('title', config.title)!
		config.meta_image = p_meta.get_default('image', config.image)!
		if p_meta.exists('description') {
			config.description = p_meta.get('description')!
		}

		meta_action.done = true
	}

	// ============================================================
	// STEP 3: Configure content imports
	// ============================================================
	console.print_item('Step 3: Configuring content imports')
	play_imports(mut plbook, mut config)!

	// ============================================================
	// STEP 4: Configure navigation menu
	// ============================================================
	console.print_item('Step 4: Configuring navigation menu')
	play_navbar(mut plbook, mut config)!

	// ============================================================
	// STEP 5: Configure footer
	// ============================================================
	console.print_item('Step 5: Configuring footer')
	play_footer(mut plbook, mut config)!

	// ============================================================
	// STEP 6: Configure announcement bar (optional)
	// ============================================================
	console.print_item('Step 6: Configuring announcement bar (if present)')
	play_announcement(mut plbook, mut config)!

	// ============================================================
	// STEP 7: Configure publish destinations
	// ============================================================
	console.print_item('Step 7: Configuring publish destinations')
	play_publishing(mut plbook, mut config)!

	// ============================================================
	// STEP 8: Build pages and navigation structure
	// ============================================================
	console.print_item('Step 8: Processing pages and building navigation')
	play_pages(mut plbook, mut website)!

	console.print_green('Site configuration complete')
}
