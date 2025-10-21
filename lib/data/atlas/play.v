module atlas

import incubaid.herolib.core.playbook { PlayBook }

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

		// Get or create atlas
		mut atlas_instance := atlases[name] or {
			mut new_atlas := new(name: name)!
			atlases[name] = new_atlas
			new_atlas
		}

		path := p.get('path')!
		atlas_instance.scan(path: path, save: true)!
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
