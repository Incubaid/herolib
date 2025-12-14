//! HeroPrompt API Endpoints
//!
//! REST API for workspace, directory, file, and search operations.
module heroprompt

import json
import veb
import incubaid.herolib.ai.heroprompt_backend

// API Response Structures

struct ApiResponse {
	status  string
	message string
}

struct WorkspaceData {
	id         string
	name       string
	dirs       []DirData
	created_at i64
	updated_at i64
}

struct DirData {
	id         string
	path       string
	name       string
	created_at i64
}

struct WorkspaceResponse {
	status    string
	workspace WorkspaceData
}

struct WorkspacesResponse {
	status           string
	workspaces       []WorkspaceData
	active_workspace string
}

struct DirResponse {
	status string
	dir    DirData
}

struct FileTreeNode {
	@type    string         @[json: 'type']
	name     string
	path     string
	size     i64
	children []FileTreeNode
}

struct FileTreeResponse {
	status string
	tree   map[string]FileTreeNode
}

struct FileContentResponse {
	status  string
	path    string
	content string
}

struct SearchResultData {
	path        string
	line_number int
	line        string
	context     string
}

struct SearchResponse {
	status  string
	results []SearchResultData
}

struct ContextResponse {
	status  string
	context string
}

// workspace_to_api converts a backend Workspace to API format.
fn workspace_to_api(ws heroprompt_backend.Workspace) WorkspaceData {
	return WorkspaceData{
		id:         ws.id
		name:       ws.name
		dirs:       ws.dirs.map(fn (d heroprompt_backend.Directory) DirData {
			return DirData{
				id:         d.id
				path:       d.path
				name:       d.name
				created_at: d.created_at
			}
		})
		created_at: ws.created_at
		updated_at: ws.updated_at
	}
}

// Workspace Endpoints

@['/api/workspaces'; get]
pub fn (mut app App) api_get_workspaces(mut ctx Context) veb.Result {
	ctx.set_content_type('application/json')
	app.log_api('GET /api/workspaces')

	workspaces := app.backend.list_workspaces()
	active := if app.active_workspace != '' {
		app.active_workspace
	} else if workspaces.len > 0 {
		workspaces[0].id
	} else {
		''
	}

	app.log_api('Returning ${workspaces.len} workspaces')
	return ctx.text(json.encode(WorkspacesResponse{
		status:           'ok'
		workspaces:       workspaces.map(workspace_to_api)
		active_workspace: active
	}))
}

@['/api/workspaces'; post]
pub fn (mut app App) api_create_workspace(mut ctx Context) veb.Result {
	ctx.set_content_type('application/json')
	app.log_api('POST /api/workspaces')

	params := json.decode(map[string]string, ctx.req.data) or { map[string]string{} }
	name := params['name'] or { '' }

	mut backend := app.backend
	ws := backend.create_workspace(name: name) or {
		app.log_api_error('Failed to create workspace: ${err}')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: '${err}'}))
	}

	app.active_workspace = ws.id
	app.log_api('Created workspace: ${ws.name} (${ws.id})')
	return ctx.text(json.encode(WorkspaceResponse{status: 'ok', workspace: workspace_to_api(*ws)}))
}

@['/api/workspaces/:id'; delete]
pub fn (mut app App) api_delete_workspace(mut ctx Context, id string) veb.Result {
	ctx.set_content_type('application/json')
	app.log_api('DELETE /api/workspaces/${id}')

	mut backend := app.backend
	backend.delete_workspace(id: id) or {
		app.log_api_error('Workspace not found: ${id}')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: 'Workspace not found'}))
	}

	if app.active_workspace == id {
		workspaces := backend.list_workspaces()
		app.active_workspace = if workspaces.len > 0 { workspaces[0].id } else { '' }
	}

	app.log_api('Deleted workspace: ${id}')
	return ctx.text(json.encode(ApiResponse{status: 'ok', message: 'Workspace deleted'}))
}

@['/api/workspaces/:id/activate'; post]
pub fn (mut app App) api_activate_workspace(mut ctx Context, id string) veb.Result {
	ctx.set_content_type('application/json')
	app.log_api('POST /api/workspaces/${id}/activate')

	ws := app.backend.get_workspace(id: id) or {
		app.log_api_error('Workspace not found: ${id}')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: 'Workspace not found'}))
	}

	app.active_workspace = id
	app.log_api('Activated workspace: ${ws.name}')
	return ctx.text(json.encode(WorkspaceResponse{status: 'ok', workspace: workspace_to_api(*ws)}))
}

@['/api/workspaces/:id/rename'; post]
pub fn (mut app App) api_rename_workspace(mut ctx Context, id string) veb.Result {
	ctx.set_content_type('application/json')
	app.log_api('POST /api/workspaces/${id}/rename')

	params := json.decode(map[string]string, ctx.req.data) or { map[string]string{} }
	name := params['name'] or { '' }

	if name == '' {
		app.log_api_error('Rename failed - name is required')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: 'Name is required'}))
	}

	mut backend := app.backend
	backend.update_workspace(id: id, name: name) or {
		app.log_api_error('Workspace not found: ${id}')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: 'Workspace not found'}))
	}

	app.log_api('Renamed workspace ${id} to: ${name}')
	return ctx.text(json.encode(ApiResponse{status: 'ok', message: 'Workspace renamed'}))
}

// Directory Endpoints

@['/api/workspaces/:id/dirs'; post]
pub fn (mut app App) api_add_dir(mut ctx Context, id string) veb.Result {
	ctx.set_content_type('application/json')
	app.log_api('POST /api/workspaces/${id}/dirs')

	params := json.decode(map[string]string, ctx.req.data) or { map[string]string{} }
	path := params['path'] or { '' }
	name := params['name'] or { '' }

	if path == '' {
		app.log_api_error('Add dir failed - path is required')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: 'Path is required'}))
	}

	mut backend := app.backend
	dir := backend.add_dir(workspace_id: id, path: path, name: name) or {
		app.log_api_error('Failed to add dir: ${err}')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: '${err}'}))
	}

	app.log_api('Added directory: ${dir.path}')
	return ctx.text(json.encode(DirResponse{
		status: 'ok'
		dir:    DirData{id: dir.id, path: dir.path, name: dir.name, created_at: dir.created_at}
	}))
}

@['/api/workspaces/:id/repos'; post]
pub fn (mut app App) api_add_repo(mut ctx Context, id string) veb.Result {
	return app.api_add_dir(mut ctx, id)
}

@['/api/workspaces/:ws_id/dirs/:dir_id'; delete]
pub fn (mut app App) api_remove_dir(mut ctx Context, ws_id string, dir_id string) veb.Result {
	ctx.set_content_type('application/json')
	app.log_api('DELETE /api/workspaces/${ws_id}/dirs/${dir_id}')

	mut backend := app.backend
	backend.delete_dir(workspace_id: ws_id, dir_id: dir_id) or {
		app.log_api_error('Directory not found: ${dir_id}')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: 'Directory not found'}))
	}

	app.log_api('Removed directory: ${dir_id}')
	return ctx.text(json.encode(ApiResponse{status: 'ok', message: 'Directory removed'}))
}

@['/api/workspaces/:ws_id/repos/:repo_id'; delete]
pub fn (mut app App) api_remove_repo(mut ctx Context, ws_id string, repo_id string) veb.Result {
	return app.api_remove_dir(mut ctx, ws_id, repo_id)
}

@['/api/workspaces/:id/files'; get]
pub fn (mut app App) api_get_files(mut ctx Context, id string) veb.Result {
	ctx.set_content_type('application/json')
	app.log_api('GET /api/workspaces/${id}/files')

	ws := app.backend.get_workspace(id: id) or {
		app.log_api_error('Workspace not found: ${id}')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: 'Workspace not found'}))
	}

	mut tree := map[string]FileTreeNode{}
	for dir in ws.dirs {
		file_tree := heroprompt_backend.get_file_tree(dir_path: dir.path) or {
			app.log_api_error('Failed to get file tree for: ${dir.path}')
			tree[dir.id] = FileTreeNode{@type: 'dir', name: dir.name, path: dir.path, children: []}
			continue
		}
		tree[dir.id] = file_info_to_node(file_tree, dir.path)
	}

	app.log_api('Built file tree for ${ws.dirs.len} directories')
	return ctx.text(json.encode(FileTreeResponse{status: 'ok', tree: tree}))
}

fn file_info_to_node(info heroprompt_backend.FileInfo, base_path string) FileTreeNode {
	node_path := if info.path == '' || info.path == '.' { base_path } else { '${base_path}/${info.path}' }

	return FileTreeNode{
		@type:    if info.is_dir { 'dir' } else { 'file' }
		name:     info.name
		path:     node_path
		size:     info.size
		children: info.children.map(fn [base_path] (c heroprompt_backend.FileInfo) FileTreeNode {
			return file_info_to_node(c, base_path)
		})
	}
}

// File Content Endpoints

@['/api/file'; get]
pub fn (mut app App) api_get_file_content(mut ctx Context) veb.Result {
	ctx.set_content_type('application/json')

	path := ctx.query['path'] or { '' }
	app.log_api('GET /api/file?path=${path}')

	if path == '' {
		app.log_api_error('Get file content failed - path is required')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: 'Path is required'}))
	}

	content := heroprompt_backend.get_file_content(path: path) or {
		app.log_api_error('Failed to read file: ${err}')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: '${err}'}))
	}

	app.log_api('Read file content: ${path} (${content.len} bytes)')
	return ctx.text(json.encode(FileContentResponse{status: 'ok', path: path, content: content}))
}

// Search Endpoints

@['/api/workspaces/:id/search'; get]
pub fn (mut app App) api_search(mut ctx Context, id string) veb.Result {
	ctx.set_content_type('application/json')

	query := ctx.query['q'] or { '' }
	app.log_api('GET /api/workspaces/${id}/search?q=${query}')

	if query == '' {
		return ctx.text(json.encode(SearchResponse{status: 'ok', results: []}))
	}

	results := app.backend.search(workspace_id: id, query: query, max_results: 100) or {
		app.log_api_error('Search failed: ${err}')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: '${err}'}))
	}

	app.log_api('Search returned ${results.len} results')
	return ctx.text(json.encode(SearchResponse{
		status:  'ok'
		results: results.map(fn (r heroprompt_backend.SearchResult) SearchResultData {
			return SearchResultData{
				path:        r.path
				line_number: r.line_number
				line:        r.line
				context:     r.context
			}
		})
	}))
}

// Context Generation Endpoints

@['/api/workspaces/:id/context'; post]
pub fn (mut app App) api_generate_context(mut ctx Context, id string) veb.Result {
	ctx.set_content_type('application/json')
	app.log_api('POST /api/workspaces/${id}/context')

	request := json.decode(map[string][]string, ctx.req.data) or { map[string][]string{} }
	file_paths := request['files'] or { []string{} }

	if file_paths.len == 0 {
		app.log_api('No files provided for context generation')
		return ctx.text(json.encode(ContextResponse{status: 'ok', context: ''}))
	}

	context := app.backend.generate_context(workspace_id: id, file_paths: file_paths) or {
		app.log_api_error('Failed to generate context: ${err}')
		return ctx.text(json.encode(ApiResponse{status: 'error', message: '${err}'}))
	}

	app.log_api('Generated context for ${file_paths.len} files (${context.len} chars)')
	return ctx.text(json.encode(ContextResponse{status: 'ok', context: context}))
}
