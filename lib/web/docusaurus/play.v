module docusaurus

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.web.site
import os

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'docusaurus.') {
		return
	}

	// there should be 1 define section
	mut action_define := plbook.ensure_once(filter: 'docusaurus.define')!
	mut param_define := action_define.params

	config_set(
		path_build:      param_define.get_default('path_build', '')!
		path_publish:    param_define.get_default('path_publish', '')!
		reset:           param_define.get_default_false('reset')
		template_update: param_define.get_default_false('template_update')
		install:         param_define.get_default_false('install')
	)!

	site_name := param_define.get('name') or {
		return error('In docusaurus.define, param "name" is required.')
	}

	dsite_define(site_name)!

	action_define.done = true
	mut dsite := dsite_get(site_name)!

	dsite.generate()!

	mut actions_dev := plbook.find(filter: 'docusaurus.dev')!
	if actions_dev.len > 1 {
		return error('Multiple "docusaurus.dev" actions found. Only one is allowed.')
	}
	for mut action in actions_dev {
		mut p := action.params
		dsite.dev(
			host: p.get_default('host', 'localhost')!
			port: p.get_int_default('port', 3000)!
			open: p.get_default_false('open')
		)!
		action.done = true
	}

	mut actions_build := plbook.find(filter: 'docusaurus.build')!
	if actions_build.len > 1 {
		return error('Multiple "docusaurus.build" actions found. Only one is allowed.')
	}
	for mut action in actions_build {
		dsite.build()!
		action.done = true
	}

	mut actions_export := plbook.find(filter: 'docusaurus.publish')!
	if actions_export.len > 1 {
		return error('Multiple "docusaurus.publish" actions found. Only one is allowed.')
	}
	for mut action in actions_export {
		dsite.build_publish()!
		action.done = true
	}

	plbook.ensure_processed(filter: 'docusaurus.')!
}
