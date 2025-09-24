module doctree

import freeflowuniverse.herolib.core.playbook { PlayBook }
// import freeflowuniverse.herolib.ui.console

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'doctree.') {
		return
	}

	mut doctrees := map[string]&Tree{}

	mut collection_actions := plbook.find(filter: 'doctree.scan')!
	for mut action in collection_actions {
		mut p := action.params
		name := p.get_default('name', 'main')!
		mut doctree := doctrees[name] or {
			mut newdtr := new(name: name)!
			doctrees[name] = newdtr
			newdtr
		}
		path := p.get_default('path', '')!
		git_url := p.get_default('git_url', '')!
		git_reset := p.get_default_false('git_reset')
		git_pull := p.get_default_false('git_pull')
		doctree.scan(path: path, git_url: git_url, git_reset: git_reset, git_pull: git_pull)!
		action.done = true
		tree_set(doctree)
	}

	mut export_actions := plbook.find(filter: 'doctree.export')!
	if export_actions.len == 0 && collection_actions.len > 0 {
		// Only auto-export if we have collections to export
		name0 := 'main'
		mut doctree0 := doctrees[name0] or { panic("can't find doctree with name ${name0}") }
		doctree0.export()!
	}
	if export_actions.len > 0 {
		if collection_actions.len == 0 {
			println(plbook)
			return error('No collections configured, use !!doctree.collection..., otherwise cannot export')
		}
	}

	for mut action in export_actions {
		mut p := action.params
		name := p.get_default('name', 'main')!
		destination := p.get('destination')!
		reset := p.get_default_false('reset')
		exclude_errors := p.get_default_true('exclude_errors')
		mut doctree := doctrees[name] or { return error("can't find doctree with name ${name}") }
		doctree.export(
			destination:    destination
			reset:          reset
			exclude_errors: exclude_errors
		)!
		action.done = true
	}

	// println(tree_list())	
	// println(tree_get("main")!)
	// panic("sd")
}
