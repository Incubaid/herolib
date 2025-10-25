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

	// Process scan actions - scan directories for collections
	mut scan_actions := plbook.find(filter: 'atlas.scan')!
	for mut action in scan_actions {
		mut p := action.params
		name := p.get_default('name', 'main')!
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
		if git_url != '' {
			// Clone or get the repository using gittools
			mut gs := gittools.new(coderoot: p.get_default('git_root', '~/code')!)!
			mut repo := gs.get_repo(url: git_url)!
			path = repo.path()
		}
		if path == '' {
			return error('Either "path" or "git_url" must be provided for atlas.scan action.')
		}
		meta_path := p.get_default('meta_path', '')!
		atlas_instance.scan(path: path, meta_path: meta_path, ignore: ignore)!
		action.done = true
		atlas_set(atlas_instance)
	}

	// Process export actions - export collections to destination
	mut export_actions := plbook.find(filter: 'atlas.export')!

	// Process explicit export actions
	for mut action in export_actions {
		mut p := action.params
		name := p.get_default('name', 'main')!
		destination := p.get('destination')!
		reset := p.get_default_true('reset')
		include := p.get_default_true('include')
		redis := p.get_default_true('redis')

		mut atlas_instance := atlases[name] or {
			return error("Atlas '${name}' not found. Use !!atlas.scan or !!atlas.load first.")
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
