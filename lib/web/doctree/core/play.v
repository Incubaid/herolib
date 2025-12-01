module core

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.develop.gittools
import incubaid.herolib.ui.console
import os

// Play function to process HeroScript actions for DocTree
pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'doctree.') {
		return
	}

	// Track which doctrees we've processed in this playbook
	mut processed_doctreees := map[string]bool{}

	mut name := ''

	// Process scan actions - scan directories for collections
	mut scan_actions := plbook.find(filter: 'doctree.scan')!
	for mut action in scan_actions {
		mut p := action.params
		name = p.get_default('name', 'main')!
		ignore := p.get_list_default('ignore', [])!
		console.print_item("Scanning DocTree '${name}' with ignore patterns: ${ignore}")
		// Get or create doctree from global map
		mut doctree_instance := if exists(name) {
			get(name)!
		} else {
			console.print_debug('DocTree not found, creating a new one')
			new(name: name)!
		}
		processed_doctreees[name] = true

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
			return error('Either "path" or "git_url" must be provided for doctree.scan action.')
		}
		doctree_instance.scan(path: path, ignore: ignore)!
		action.done = true

		// No need to call set() again - doctree is already in global map from new()
		// and we're modifying it by reference
	}

	// Run init_post on all processed doctrees
	for doctree_name, _ in processed_doctreees {
		mut doctree_instance_post := get(doctree_name)!
		doctree_instance_post.init_post()!
	}

	// Process export actions - export collections to destination
	mut export_actions := plbook.find(filter: 'doctree.export')!

	// Process explicit export actions
	for mut action in export_actions {
		mut p := action.params
		name = p.get_default('name', 'main')!
		destination := p.get_default('destination', '${os.home_dir()}/hero/var/doctree_export')!
		reset := p.get_default_true('reset')
		include := p.get_default_true('include')
		redis := p.get_default_true('redis')

		mut doctree_instance := get(name) or {
			return error("DocTree '${name}' not found. Use !!doctree.scan first.")
		}

		doctree_instance.export(
			destination: destination
			reset:       reset
			include:     include
			redis:       redis
		)!
		action.done = true
	}
}
