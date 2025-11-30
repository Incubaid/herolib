module atlas

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.develop.gittools
import incubaid.herolib.ui.console
import os

// Play function to process HeroScript actions for Atlas
pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'atlas.') {
		return
	}

	// Track which atlases we've processed in this playbook
	mut processed_atlases := map[string]bool{}

	mut name := ''

	// Process scan actions - scan directories for collections
	mut scan_actions := plbook.find(filter: 'atlas.scan')!
	for mut action in scan_actions {
		mut p := action.params
		name = p.get_default('name', 'main')!
		ignore := p.get_list_default('ignore', [])!
		console.print_item("Scanning Atlas '${name}' with ignore patterns: ${ignore}")
		// Get or create atlas from global map
		mut atlas_instance := if exists(name) {
			get(name)!
		} else {
			console.print_debug('Atlas not found, creating a new one')
			new(name: name)!
		}
		processed_atlases[name] = true

		mut path := p.get_default('path', '')!

		// NEW: Support git URL as source
		mut git_url := p.get_default('git_url', '')!
		mut git_pull := p.get_default_false('git_pull')
		if git_url != '' {
			// Clone or get the repository using gittools
			path = gittools.path(
				git_pull: git_pull
				git_url:  git_url
			)!.path
		}
		if path == '' {
			return error('Either "path" or "git_url" must be provided for atlas.scan action.')
		}
		atlas_instance.scan(path: path, ignore: ignore)!
		action.done = true

		// No need to call set() again - atlas is already in global map from new()
		// and we're modifying it by reference
	}

	// Run init_post on all processed atlases
	for atlas_name, _ in processed_atlases {
		mut atlas_instance_post := get(atlas_name)!
		atlas_instance_post.init_post()!
	}

	// Process export actions - export collections to destination
	mut export_actions := plbook.find(filter: 'atlas.export')!

	// Process explicit export actions
	for mut action in export_actions {
		mut p := action.params
		name = p.get_default('name', 'main')!
		destination := p.get_default('destination', '${os.home_dir()}/hero/var/atlas_export')!
		reset := p.get_default_true('reset')
		include := p.get_default_true('include')
		redis := p.get_default_true('redis')

		mut atlas_instance := get(name) or {
			return error("Atlas '${name}' not found. Use !!atlas.scan first.")
		}

		atlas_instance.export(
			destination: destination
			reset:       reset
			include:     include
			redis:       redis
		)!
		action.done = true
	}
}
