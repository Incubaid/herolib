module site

import os
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.core.texttools
import time
import incubaid.herolib.ui.console

// ============================================================
// PUBLISHING: Configure build and publish destinations
// ============================================================
fn play_publishing(mut plbook PlayBook, mut config SiteConfig) ! {
	// Production publish destinations
	mut build_dest_actions := plbook.find(filter: 'site.publish')!
	for mut action in build_dest_actions {
		mut p := action.params

		path := p.get('path') or {
			return error('!!site.publish: must specify "path"')
		}

		mut dest := BuildDest{
			path:     path
			ssh_name: p.get_default('ssh_name', '')!
		}
		config.build_dest << dest
		action.done = true
	}

	// Development publish destinations
	mut build_dest_dev_actions := plbook.find(filter: 'site.publish_dev')!
	for mut action in build_dest_dev_actions {
		mut p := action.params

		path := p.get('path') or {
			return error('!!site.publish_dev: must specify "path"')
		}

		mut dest := BuildDest{
			path:     path
			ssh_name: p.get_default('ssh_name', '')!
		}
		config.build_dest_dev << dest
		action.done = true
	}
}
