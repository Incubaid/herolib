module ui

import veb
import os
import json
import freeflowuniverse.herolib.develop.heroprompt as hp
import freeflowuniverse.herolib.develop.codewalker

// ============================================================================
// Types and Structures
// ============================================================================

struct DirResp {
	path  string
	items []hp.ListItem
}

struct SearchResult {
	name      string
	path      string
	full_path string
	type_     string @[json: 'type']
}

struct SearchResponse {
	query   string
	results []SearchResult
	count   string
}

struct RecursiveListResponse {
	path     string
	children []map[string]string
}

// ============================================================================
// Utility Functions
// ============================================================================

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

fn set_json_content_type(mut ctx Context) {
	ctx.set_content_type('application/json')
}

fn get_workspace_or_error(name string, mut ctx Context) ?&hp.Workspace {
	wsp := hp.get(name: name, create: false) or {
		set_json_content_type(mut ctx)
		ctx.text(json_error('workspace not found'))
		return none
	}
	return wsp
}

// ============================================================================
// Search Functionality
// ============================================================================

fn search_files_recursive(base_path string, query string) []SearchResult {
	mut results := []SearchResult{}
	query_lower := query.to_lower()

	// Create ignore matcher for consistent filtering
	ignore_matcher := codewalker.gitignore_matcher_new()

	search_directory_with_ignore(base_path, base_path, query_lower, &ignore_matcher, mut
		results)
	return results
}

fn search_directory_with_ignore(base_path string, current_path string, query_lower string, ignore_matcher &codewalker.IgnoreMatcher, mut results []SearchResult) {
	entries := os.ls(current_path) or { return }

	for entry in entries {
		full_path := os.join_path(current_path, entry)

		// Calculate relative path for ignore checking
		mut rel_path := full_path
		if full_path.starts_with(base_path) {
			rel_path = full_path[base_path.len..]
			if rel_path.starts_with('/') {
				rel_path = rel_path[1..]
			}
		}

		// Check if this entry should be ignored
		if ignore_matcher.is_ignored(rel_path) {
			continue
		}

		// Check if filename or path matches search query
		if entry.to_lower().contains(query_lower) || rel_path.to_lower().contains(query_lower) {
			results << SearchResult{
				name:      entry
				path:      rel_path
				full_path: full_path
				type_:     if os.is_dir(full_path) { 'directory' } else { 'file' }
			}
		}

		// Recursively search subdirectories
		if os.is_dir(full_path) {
			search_directory_with_ignore(base_path, full_path, query_lower, ignore_matcher, mut
				results)
		}
	}
}

// ============================================================================
// Workspace Management API Endpoints
// ============================================================================

// List all workspaces
@['/api/heroprompt/workspaces'; get]
pub fn (app &App) api_heroprompt_list_workspaces(mut ctx Context) veb.Result {
	mut names := []string{}
	ws := hp.list_workspaces_fromdb() or { []&hp.Workspace{} }
	for w in ws {
		names << w.name
	}
	set_json_content_type(mut ctx)
	return ctx.text(json.encode(names))
}

// Create a new workspace
@['/api/heroprompt/workspaces'; post]
pub fn (app &App) api_heroprompt_create_workspace(mut ctx Context) veb.Result {
	name_input := ctx.form['name'] or { '' }

	// Validate workspace name
	mut name := name_input.trim(' \t\n\r')
	if name.len == 0 {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('workspace name is required'))
	}

	// Create workspace
	wsp := hp.get(name: name, create: true) or {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('create failed'))
	}

	set_json_content_type(mut ctx)
	return ctx.text(json.encode({
		'name': wsp.name
	}))
}

// Get workspace details
@['/api/heroprompt/workspaces/:name'; get]
pub fn (app &App) api_heroprompt_get_workspace(mut ctx Context, name string) veb.Result {
	wsp := get_workspace_or_error(name, mut ctx) or { return ctx.text('') }

	set_json_content_type(mut ctx)
	return ctx.text(json.encode({
		'name':           wsp.name
		'selected_files': wsp.selected_children().len.str()
	}))
}

// Update workspace
@['/api/heroprompt/workspaces/:name'; put]
pub fn (app &App) api_heroprompt_update_workspace(mut ctx Context, name string) veb.Result {
	wsp := get_workspace_or_error(name, mut ctx) or { return ctx.text('') }

	new_name := ctx.form['name'] or { name }

	// Update the workspace
	updated_wsp := wsp.update_workspace(name: new_name) or {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('failed to update workspace'))
	}

	set_json_content_type(mut ctx)
	return ctx.text(json.encode({
		'name': updated_wsp.name
	}))
}

// Delete workspace (using POST for VEB framework compatibility)
@['/api/heroprompt/workspaces/:name/delete'; post]
pub fn (app &App) api_heroprompt_delete_workspace(mut ctx Context, name string) veb.Result {
	wsp := get_workspace_or_error(name, mut ctx) or { return ctx.text('') }

	// Delete the workspace
	wsp.delete_workspace() or {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('failed to delete workspace'))
	}

	set_json_content_type(mut ctx)
	return ctx.text(json_success())
}

// ============================================================================
// File and Directory Operations API Endpoints
// ============================================================================

// List directory contents
@['/api/heroprompt/directory'; get]
pub fn (app &App) api_heroprompt_list_directory(mut ctx Context) veb.Result {
	wsname := ctx.query['name'] or { 'default' }
	path_q := ctx.query['path'] or { '' }
	base_path := ctx.query['base'] or { '' }

	if base_path.len == 0 {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('base path is required'))
	}

	wsp := get_workspace_or_error(wsname, mut ctx) or { return ctx.text('') }

	items := wsp.list_dir(base_path, path_q) or {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('cannot list directory'))
	}

	set_json_content_type(mut ctx)
	return ctx.text(json.encode(DirResp{
		path:  if path_q.len > 0 { path_q } else { base_path }
		items: items
	}))
}

// Get file content
@['/api/heroprompt/file'; get]
pub fn (app &App) api_heroprompt_get_file(mut ctx Context) veb.Result {
	wsname := ctx.query['name'] or { 'default' }
	path_q := ctx.query['path'] or { '' }

	if path_q.len == 0 {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('path required'))
	}

	// Validate file exists and is readable
	if !os.is_file(path_q) {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('not a file'))
	}

	content := os.read_file(path_q) or {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('failed to read file'))
	}

	set_json_content_type(mut ctx)
	return ctx.text(json.encode({
		'language': detect_lang(path_q)
		'content':  content
	}))
}

// Add file to workspace
@['/api/heroprompt/workspaces/:name/files'; post]
pub fn (app &App) api_heroprompt_add_file(mut ctx Context, name string) veb.Result {
	path := ctx.form['path'] or { '' }
	if path.len == 0 {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('path required'))
	}

	mut wsp := get_workspace_or_error(name, mut ctx) or { return ctx.text('') }

	wsp.add_file(path: path) or {
		set_json_content_type(mut ctx)
		return ctx.text(json_error(err.msg()))
	}

	set_json_content_type(mut ctx)
	return ctx.text(json_success())
}

// Add directory to workspace
@['/api/heroprompt/workspaces/:name/dirs'; post]
pub fn (app &App) api_heroprompt_add_directory(mut ctx Context, name string) veb.Result {
	path := ctx.form['path'] or { '' }
	if path.len == 0 {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('path required'))
	}

	mut wsp := get_workspace_or_error(name, mut ctx) or { return ctx.text('') }

	wsp.add_dir(path: path) or {
		set_json_content_type(mut ctx)
		return ctx.text(json_error(err.msg()))
	}

	set_json_content_type(mut ctx)
	return ctx.text(json_success())
}

// ============================================================================
// Prompt Generation and Search API Endpoints
// ============================================================================

// Generate prompt from workspace selection
@['/api/heroprompt/workspaces/:name/prompt'; post]
pub fn (app &App) api_heroprompt_generate_prompt(mut ctx Context, name string) veb.Result {
	text := ctx.form['text'] or { '' }
	selected_paths_json := ctx.form['selected_paths'] or { '[]' }

	wsp := get_workspace_or_error(name, mut ctx) or { return ctx.text('') }

	// Parse selected paths
	selected_paths := json.decode([]string, selected_paths_json) or {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('invalid selected paths format'))
	}

	// Generate prompt with selected paths
	prompt := wsp.prompt_with_selection(text: text, selected_paths: selected_paths) or {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('failed to generate prompt: ${err.msg()}'))
	}

	ctx.set_content_type('text/plain')
	return ctx.text(prompt)
}

// Search files in workspace
@['/api/heroprompt/workspaces/:name/search'; get]
pub fn (app &App) api_heroprompt_search_files(mut ctx Context, name string) veb.Result {
	query := ctx.query['q'] or { '' }
	base_path := ctx.query['base'] or { '' }

	// Validate input parameters
	if query.len == 0 {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('search query required'))
	}

	if base_path.len == 0 {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('base path required for search'))
	}

	wsp := get_workspace_or_error(name, mut ctx) or { return ctx.text('') }

	// Perform search using improved search function
	results := search_files_recursive(base_path, query)

	// Build response
	response := SearchResponse{
		query:   query
		results: results
		count:   results.len.str()
	}

	set_json_content_type(mut ctx)
	return ctx.text(json.encode(response))
}

// Get workspace selected children
@['/api/heroprompt/workspaces/:name/children'; get]
pub fn (app &App) api_heroprompt_get_workspace_children(mut ctx Context, name string) veb.Result {
	wsp := get_workspace_or_error(name, mut ctx) or { return ctx.text('') }

	children := wsp.selected_children()
	set_json_content_type(mut ctx)
	return ctx.text(json.encode(children))
}

// Get all recursive children of a directory (for directory selection)
@['/api/heroprompt/workspaces/:name/list'; get]
pub fn (app &App) api_heroprompt_list_directory_recursive(mut ctx Context, name string) veb.Result {
	path_q := ctx.query['path'] or { '' }
	if path_q.len == 0 {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('path parameter is required'))
	}

	wsp := get_workspace_or_error(name, mut ctx) or { return ctx.text('') }

	// Get all recursive children of the directory
	children := get_recursive_directory_children(path_q) or {
		set_json_content_type(mut ctx)
		return ctx.text(json_error('failed to list directory: ${err.msg()}'))
	}

	// Build response
	response := RecursiveListResponse{
		path:     path_q
		children: children
	}

	set_json_content_type(mut ctx)
	return ctx.text(json.encode(response))
}

// ============================================================================
// Directory Traversal Helper Functions
// ============================================================================

// Get all recursive children of a directory with proper gitignore filtering
fn get_recursive_directory_children(dir_path string) ![]map[string]string {
	// Validate directory exists
	if !os.exists(dir_path) {
		return error('directory does not exist: ${dir_path}')
	}
	if !os.is_dir(dir_path) {
		return error('path is not a directory: ${dir_path}')
	}

	// Create ignore matcher with default patterns for consistent filtering
	ignore_matcher := codewalker.gitignore_matcher_new()

	mut results := []map[string]string{}
	collect_directory_children_recursive(dir_path, dir_path, &ignore_matcher, mut results) or {
		return error('failed to collect directory children: ${err.msg()}')
	}
	return results
}

// Recursively collect all children with proper gitignore filtering
fn collect_directory_children_recursive(base_dir string, current_dir string, ignore_matcher &codewalker.IgnoreMatcher, mut results []map[string]string) ! {
	entries := os.ls(current_dir) or { return error('cannot list directory: ${current_dir}') }

	for entry in entries {
		full_path := os.join_path(current_dir, entry)

		// Calculate relative path from base directory for ignore checking
		rel_path := calculate_relative_path(full_path, base_dir)

		// Check if this entry should be ignored using proper gitignore logic
		if ignore_matcher.is_ignored(rel_path) {
			continue
		}

		// Add this entry to results using full absolute path to match tree format
		results << {
			'name': entry
			'path': full_path
			'type': if os.is_dir(full_path) { 'directory' } else { 'file' }
		}

		// If it's a directory, recursively collect its children
		if os.is_dir(full_path) {
			collect_directory_children_recursive(base_dir, full_path, ignore_matcher, mut
				results) or {
				// Continue on error to avoid stopping the entire operation
				continue
			}
		}
	}
}

// Calculate relative path from base directory
fn calculate_relative_path(full_path string, base_dir string) string {
	mut rel_path := full_path
	if full_path.starts_with(base_dir) {
		rel_path = full_path[base_dir.len..]
		if rel_path.starts_with('/') {
			rel_path = rel_path[1..]
		}
	}
	return rel_path
}
