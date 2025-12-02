module meta

import os
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.core.texttools
import time
import incubaid.herolib.ui.console

// ============================================================
// IMPORTS: Process content imports
// ============================================================
fn play_imports(mut plbook PlayBook, mut site Site) ! {
	mut import_actions := plbook.find(filter: 'site.import')!

	for mut action in import_actions {
		mut p := action.params

		// Parse replacement patterns (comma-separated key:value pairs)
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

		// Get path (can be relative to playbook path)
		mut import_path := p.get_default('path', '')!
		if import_path != '' {
			if !import_path.starts_with('/') {
				import_path = os.abs_path('${plbook.path}/${import_path}')
			}
		}

		// Create import item
		mut import_item := ImportItem{
			url:     p.get_default('url', '')!
			path:    import_path
			dest:    p.get_default('dest', '')!
			replace: replace_map
			visible: p.get_default_false('visible')
		}

		site.imports << import_item
		action.done = true
	}
}
