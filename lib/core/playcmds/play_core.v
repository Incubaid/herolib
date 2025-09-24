module playcmds

import freeflowuniverse.herolib.develop.gittools
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import os

// -------------------------------------------------------------------
// Core play‑command processing (context, session, env‑subst, etc)
// -------------------------------------------------------------------

fn play_core(mut plbook PlayBook) ! {
	if plbook.exists(filter: 'play.') == false && plbook.exists(filter: 'play.') == false && plbook.exists(
		filter: 'core.'
	) == false {
		return
	}

	// ----------------------------------------------------------------
	// 1.  Include handling (play include / echo)
	// ----------------------------------------------------------------
	// Track included paths to prevent infinite recursion
	mut included_paths := map[string]bool{}

	for mut action_ in plbook.find(filter: 'play.*')! {
		if action_.name == 'include' {
			mut action := *action_
			mut toreplace := action.params.get_default('replace', '')!
			mut playrunpath := action.params.get_default('path', '')!
			if playrunpath.len == 0 {
				action.name = 'pull'
				mypath := gittools.path(
					path:      playrunpath
					git_url:   action.params.get_default('git_url', '')!
					git_reset: action.params.get_default_false('git_reset')
					git_pull:  action.params.get_default_false('git_pull')
				)!
				playrunpath = mypath.path
			}
			if playrunpath.len == 0 {
				return error("can't run a heroscript didn't find url or path.")
			}

			// console.print_debug('play run:\n${action_}')
			if !playrunpath.starts_with('/') {
				playrunpath = os.abs_path('${plbook.path}/${playrunpath}')
			}

			console.print_debug('play run include path:${playrunpath}')

			// Check for cycle detection
			if playrunpath in included_paths {
				console.print_debug('Skipping already included path: ${playrunpath}')
				continue
			}
			toreplacedict := texttools.to_map(toreplace)
			included_paths[playrunpath] = true
			plbook.add(path: playrunpath, replace: toreplacedict)!

			action.done = true
		}
		if action_.name == 'echo' {
			content := action_.params.get_default('content', "didn't find content")!
			console.print_header(content)
		}
	}

	// ----------------------------------------------------------------
	// 2.  Session environment handling
	// ----------------------------------------------------------------
	// Guard – make sure a session exists
	mut session := plbook.session

	// !!session.env_set / env_set_once
	for mut action in plbook.find(filter: 'session.')! {
		mut p := action.params
		match action.name {
			'env_set' {
				key := p.get('key')!
				val := p.get('val') or { p.get('value')! }
				session.env_set(key, val)!
			}
			'env_set_once' {
				key := p.get('key')!
				val := p.get('val') or { p.get('value')! }
				// Use the dedicated “set‑once” method
				session.env_set_once(key, val)!
			}
			else {}
		}
		action.done = true
	}

	// ----------------------------------------------------------------
	// 3.  Template replacement in action parameters
	// ----------------------------------------------------------------
	// Apply template replacement from session environment variables
	if session.env.len > 0 {
		// Create a map with name_fix applied to keys for template replacement
		mut env_fixed := map[string]string{}
		for key, value in session.env {
			env_fixed[texttools.name_fix(key)] = value
		}

		for mut action in plbook.actions {
			if !action.done {
				action.params.replace(env_fixed)
			}
		}
	}

	for mut action in plbook.find(filter: 'core.coderoot_set')! {
		mut p := action.params
		if p.exists('coderoot') {
			coderoot := p.get_path_create('coderoot')!
			if session.context.config.coderoot != coderoot {
				session.context.config.coderoot = coderoot
				session.context.save()!
			}
		} else {
			return error('coderoot needs to be specified')
		}
		action.done = true
	}

	for mut action in plbook.find(filter: 'core.params_context_set')! {
		mut p := action.params
		mut context_params := session.context.params()!
		for param in p.params {
			context_params.set(param.key, param.value)
		}
		session.context.save()!
		action.done = true
	}

	for mut action in plbook.find(filter: 'core.params_session_set')! {
		mut p := action.params
		for param in p.params {
			session.params.set(param.key, param.value)
		}
		session.save()!
		action.done = true
	}
}
