module docusaurus

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.data.doctree
import incubaid.herolib.ui.console
import os

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'docusaurus.') {
		return
	}

	mut dsite := process_define(mut plbook)!
	dsite.generate()!

	process_build(mut plbook, mut dsite)!
	process_publish(mut plbook, mut dsite)!
	process_dev(mut plbook, mut dsite)!

	plbook.ensure_processed(filter: 'docusaurus.')!
}

fn process_define(mut plbook PlayBook) !&DocSite {
	mut action := plbook.ensure_once(filter: 'docusaurus.define')!
	p := action.params

	doctree_dir := p.get_default('doctree_dir', '${os.home_dir()}/hero/var/doctree_export')!

	config_set(
		path_build:      p.get_default('path_build', '')!
		path_publish:    p.get_default('path_publish', '')!
		reset:           p.get_default_false('reset')
		template_update: p.get_default_false('template_update')
		install:         p.get_default_false('install')
		doctree_dir:       doctree_dir
	)!

	site_name := p.get('name') or { return error('docusaurus.define: "name" is required') }
	doctree_name := p.get_default('doctree', 'main')!

	export_doctree(doctree_name, doctree_dir)!
	dsite_define(site_name)!
	action.done = true

	return dsite_get(site_name)!
}

fn process_build(mut plbook PlayBook, mut dsite DocSite) ! {
	if !plbook.max_once(filter: 'docusaurus.build')! {
		return
	}
	mut action := plbook.get(filter: 'docusaurus.build')!
	dsite.build()!
	action.done = true
}

fn process_publish(mut plbook PlayBook, mut dsite DocSite) ! {
	if !plbook.max_once(filter: 'docusaurus.publish')! {
		return
	}
	mut action := plbook.get(filter: 'docusaurus.publish')!
	dsite.build_publish()!
	action.done = true
}

fn process_dev(mut plbook PlayBook, mut dsite DocSite) ! {
	if !plbook.max_once(filter: 'docusaurus.dev')! {
		return
	}
	mut action := plbook.get(filter: 'docusaurus.dev')!
	p := action.params
	dsite.dev(
		host: p.get_default('host', 'localhost')!
		port: p.get_int_default('port', 3000)!
		open: p.get_default_false('open')
	)!
	action.done = true
}

fn export_doctree(name string, dir string) ! {
	if !doctree.exists(name) {
		return
	}
	console.print_debug('Auto-exporting DocTree "${name}" to ${dir}')
	mut a := doctree.get(name)!
	a.export(destination: dir, reset: true, include: true, redis: false)!
}
