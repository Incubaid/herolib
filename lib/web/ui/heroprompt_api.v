module ui

import veb
import os
import json
import freeflowuniverse.herolib.develop.heroprompt as hp

// Types
struct DirResp {
	path  string
	items []hp.ListItem
}

// Utility functions
fn expand_home_path(path string) string {
	if path.starts_with('~') {
		home := os.home_dir()
		return os.join_path(home, path.all_after('~'))
	}
	return path
}

fn json_error(message string) string {
	return '{"error":"${message}"}'
}

fn json_success() string {
	return '{"ok":true}'
}

// Recursive search function
fn search_directory(dir_path string, base_path string, query_lower string, mut results []map[string]string) {
	entries := os.ls(dir_path) or { return }

	for entry in entries {
		full_path := os.join_path(dir_path, entry)

		// Skip hidden files and common ignore patterns
		if entry.starts_with('.') || entry == 'node_modules' || entry == 'target'
			|| entry == 'build' {
			continue
		}

		// Get relative path from workspace base
		mut rel_path := full_path
		if full_path.starts_with(base_path) {
			rel_path = full_path[base_path.len..]
			if rel_path.starts_with('/') {
				rel_path = rel_path[1..]
			}
		}

		// Check if filename or path matches search query
		if entry.to_lower().contains(query_lower) || rel_path.to_lower().contains(query_lower) {
			results << {
				'name':      entry
				'path':      rel_path
				'full_path': full_path
				'type':      if os.is_dir(full_path) { 'directory' } else { 'file' }
			}
		}

		// Recursively search subdirectories
		if os.is_dir(full_path) {
			search_directory(full_path, base_path, query_lower, mut results)
		}
	}
}

// APIs
@['/api/heroprompt/workspaces'; get]
pub fn (app &App) api_heroprompt_list(mut ctx Context) veb.Result {
	mut names := []string{}
	ws := hp.list_workspaces_fromdb() or { []&hp.Workspace{} }
	for w in ws {
		names << w.name
	}
	ctx.set_content_type('application/json')
	return ctx.text(json.encode(names))
}

@['/api/heroprompt/workspaces'; post]
pub fn (app &App) api_heroprompt_create(mut ctx Context) veb.Result {
	name_input := ctx.form['name'] or { '' }
	base_path_in := ctx.form['base_path'] or { '' }
	if base_path_in.len == 0 {
		return ctx.text(json_error('base_path required'))
	}

	base_path := expand_home_path(base_path_in)

	// If no name provided, generate a random name
	mut name := name_input.trim(' \t\n\r')
	if name.len == 0 {
		name = hp.generate_random_workspace_name()
	}

	wsp := hp.get(name: name, create: true, path: base_path) or {
		return ctx.text(json_error('create failed'))
	}
	ctx.set_content_type('application/json')
	return ctx.text(json.encode({
		'name':      wsp.name
		'base_path': wsp.base_path
	}))
}

@['/api/heroprompt/workspaces/:name'; get]
pub fn (app &App) api_heroprompt_get(mut ctx Context, name string) veb.Result {
	wsp := hp.get(name: name, create: false) or {
		return ctx.text(json_error('workspace not found'))
	}
	ctx.set_content_type('application/json')
	return ctx.text(json.encode({
		'name':           wsp.name
		'base_path':      wsp.base_path
		'selected_files': wsp.selected_children().len.str()
	}))
}

@['/api/heroprompt/workspaces/:name'; put]
pub fn (app &App) api_heroprompt_update(mut ctx Context, name string) veb.Result {
	wsp := hp.get(name: name, create: false) or {
		return ctx.text(json_error('workspace not found'))
	}

	new_name := ctx.form['name'] or { name }
	new_base_path_in := ctx.form['base_path'] or { wsp.base_path }
	new_base_path := expand_home_path(new_base_path_in)

	// Update the workspace using the update_workspace method
	updated_wsp := wsp.update_workspace(
		name:      new_name
		base_path: new_base_path
	) or { return ctx.text(json_error('failed to update workspace')) }

	ctx.set_content_type('application/json')
	return ctx.text(json.encode({
		'name':      updated_wsp.name
		'base_path': updated_wsp.base_path
	}))
}

// Delete endpoint using POST (VEB framework compatibility)
@['/api/heroprompt/workspaces/:name/delete'; post]
pub fn (app &App) api_heroprompt_delete(mut ctx Context, name string) veb.Result {
	wsp := hp.get(name: name, create: false) or {
		return ctx.text(json_error('workspace not found'))
	}

	// Delete the workspace
	wsp.delete_workspace() or { return ctx.text(json_error('failed to delete workspace')) }

	ctx.set_content_type('application/json')
	return ctx.text(json_success())
}

@['/api/heroprompt/directory'; get]
pub fn (app &App) api_heroprompt_directory(mut ctx Context) veb.Result {
	wsname := ctx.query['name'] or { 'default' }
	path_q := ctx.query['path'] or { '' }
	mut wsp := hp.get(name: wsname, create: false) or {
		return ctx.text(json_error('workspace not found'))
	}
	items := wsp.list_dir(path_q) or { return ctx.text(json_error('cannot list directory')) }
	ctx.set_content_type('application/json')
	return ctx.text(json.encode(DirResp{
		path:  if path_q.len > 0 { path_q } else { wsp.base_path }
		items: items
	}))
}

@['/api/heroprompt/file'; get]
pub fn (app &App) api_heroprompt_file(mut ctx Context) veb.Result {
	wsname := ctx.query['name'] or { 'default' }
	path_q := ctx.query['path'] or { '' }
	if path_q.len == 0 {
		return ctx.text(json_error('path required'))
	}
	mut base := ''
	if wsp := hp.get(name: wsname, create: false) {
		base = wsp.base_path
	}
	mut file_path := if !os.is_abs_path(path_q) && base.len > 0 {
		os.join_path(base, path_q)
	} else {
		path_q
	}
	if !os.is_file(file_path) {
		return ctx.text(json_error('not a file'))
	}
	content := os.read_file(file_path) or { return ctx.text(json_error('failed to read')) }
	ctx.set_content_type('application/json')
	return ctx.text(json.encode({
		'language': detect_lang(file_path)
		'content':  content
	}))
}

@['/api/heroprompt/workspaces/:name/files'; post]
pub fn (app &App) api_heroprompt_add_file(mut ctx Context, name string) veb.Result {
	path := ctx.form['path'] or { '' }
	if path.len == 0 {
		return ctx.text(json_error('path required'))
	}
	mut wsp := hp.get(name: name, create: false) or {
		return ctx.text(json_error('workspace not found'))
	}
	wsp.add_file(path: path) or { return ctx.text(json_error(err.msg())) }
	return ctx.text(json_success())
}

@['/api/heroprompt/workspaces/:name/dirs'; post]
pub fn (app &App) api_heroprompt_add_dir(mut ctx Context, name string) veb.Result {
	path := ctx.form['path'] or { '' }
	if path.len == 0 {
		return ctx.text(json_error('path required'))
	}
	mut wsp := hp.get(name: name, create: false) or {
		return ctx.text(json_error('workspace not found'))
	}
	wsp.add_dir(path: path) or { return ctx.text(json_error(err.msg())) }
	return ctx.text(json_success())
}

@['/api/heroprompt/workspaces/:name/prompt'; post]
pub fn (app &App) api_heroprompt_generate_prompt(mut ctx Context, name string) veb.Result {
	text := ctx.form['text'] or { '' }
	mut wsp := hp.get(name: name, create: false) or {
		ctx.set_content_type('application/json')
		return ctx.text(json_error('workspace not found'))
	}
	prompt := wsp.prompt(text: text)
	ctx.set_content_type('text/plain')
	return ctx.text(prompt)
}

@['/api/heroprompt/workspaces/:name/selection'; post]
pub fn (app &App) api_heroprompt_sync_selection(mut ctx Context, name string) veb.Result {
	paths_json := ctx.form['paths'] or { '[]' }
	mut wsp := hp.get(name: name, create: false) or {
		return ctx.text(json_error('workspace not found'))
	}

	// Clear current selection
	wsp.children.clear()

	// Parse paths and add them to workspace
	paths := json.decode([]string, paths_json) or {
		return ctx.text(json_error('invalid paths format'))
	}

	for path in paths {
		if os.is_file(path) {
			wsp.add_file(path: path) or {
				continue // Skip files that can't be added
			}
		} else if os.is_dir(path) {
			wsp.add_dir(path: path) or {
				continue // Skip directories that can't be added
			}
		}
	}

	return ctx.text(json_success())
}

@['/api/heroprompt/workspaces/:name/search'; get]
pub fn (app &App) api_heroprompt_search(mut ctx Context, name string) veb.Result {
	query := ctx.query['q'] or { '' }
	if query.len == 0 {
		return ctx.text(json_error('search query required'))
	}

	wsp := hp.get(name: name, create: false) or {
		return ctx.text(json_error('workspace not found'))
	}

	// Simple recursive file search implementation
	mut results := []map[string]string{}
	query_lower := query.to_lower()

	// Recursive function to search files
	search_directory(wsp.base_path, wsp.base_path, query_lower, mut results)

	ctx.set_content_type('application/json')

	// Manually build JSON response to avoid encoding issues
	mut json_results := '['
	for i, result in results {
		if i > 0 {
			json_results += ','
		}
		json_results += '{'
		json_results += '"name":"${result['name']}",'
		json_results += '"path":"${result['path']}",'
		json_results += '"full_path":"${result['full_path']}",'
		json_results += '"type":"${result['type']}"'
		json_results += '}'
	}
	json_results += ']'

	response := '{"query":"${query}","results":${json_results},"count":"${results.len}"}'
	return ctx.text(response)
}
