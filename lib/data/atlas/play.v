module atlas

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.develop.gittools
import incubaid.herolib.ui.console

// Play function to process HeroScript actions for Atlas
pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'atlas.') {
		return
	}

	mut atlases := map[string]&Atlas{}

	mut name := ''

	// Process scan actions - scan directories for collections
	mut scan_actions := plbook.find(filter: 'atlas.scan')!
	for mut action in scan_actions {
		mut p := action.params
		name = p.get_default('name', 'main')!
		ignore := p.get_list_default('ignore', [])!
		console.print_item("Scanning Atlas '${name}' with ignore patterns: ${ignore}\n${p}")
		// Get or create atlas
		mut atlas_instance := atlases[name] or {
			console.print_debug('Atlas not found, creating a new one')
			mut new_atlas := new(name: name)!
			atlases[name] = new_atlas
			new_atlas
		}

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

		set(atlas_instance)
	}

	mut atlas_instance_post := atlases[name] or {
		return error("Atlas '${name}' not found. Use !!atlas.scan first.")
	}

	atlas_instance_post.init_post()!

	// Process export actions - export collections to destination
	mut export_actions := plbook.find(filter: 'atlas.export')!

	// Process explicit export actions
	for mut action in export_actions {
		mut p := action.params
		name = p.get_default('name', 'main')!
		destination := p.get('destination')!
		reset := p.get_default_true('reset')
		include := p.get_default_true('include')
		redis := p.get_default_true('redis')

		mut atlas_instance := atlases[name] or {
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
