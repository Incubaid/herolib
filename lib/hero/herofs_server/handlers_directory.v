module herofs_server

import veb
import json
import freeflowuniverse.herolib.hero.herofs

// =============================================================================
// DIRECTORY ENDPOINTS
// =============================================================================

// List all directories
@['/api/dirs'; get]
pub fn (mut server FSServer) list_directories(mut ctx Context) veb.Result {
	directories := server.fs_factory.fs_dir.list() or {
		return ctx.server_error('Failed to list directories: ${err}')
	}
	return ctx.success(directories, 'Directories retrieved successfully')
}

// Get directory by ID
@['/api/dirs/:id'; get]
pub fn (mut server FSServer) get_directory(mut ctx Context, id string) veb.Result {
	dir_id := id.u32()
	if dir_id == 0 {
		return ctx.request_error('Invalid directory ID')
	}

	directory := server.fs_factory.fs_dir.get(dir_id) or {
		return ctx.not_found('Directory not found')
	}
	return ctx.success(directory, 'Directory retrieved successfully')
}

// Create new directory
@['/api/dirs'; post]
pub fn (mut server FSServer) create_directory(mut ctx Context) veb.Result {
	dir_args := json.decode(herofs.FsDirArg, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for directory creation')
	}

	mut directory := server.fs_factory.fs_dir.new(dir_args) or {
		return ctx.server_error('Failed to create directory: ${err}')
	}
	directory = server.fs_factory.fs_dir.set(directory) or {
		return ctx.server_error('Failed to save directory: ${err}')
	}

	return ctx.created(directory, 'Directory created successfully')
}

// Update directory
@['/api/dirs/:id'; put]
pub fn (mut server FSServer) update_directory(mut ctx Context, id string) veb.Result {
	dir_id := id.u32()
	if dir_id == 0 {
		return ctx.request_error('Invalid directory ID')
	}

	mut directory := json.decode(herofs.FsDir, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for directory update')
	}
	directory.id = dir_id

	directory = server.fs_factory.fs_dir.set(directory) or {
		return ctx.server_error('Failed to update directory: ${err}')
	}
	return ctx.success(directory, 'Directory updated successfully')
}

// Delete directory
@['/api/dirs/:id'; delete]
pub fn (mut server FSServer) delete_directory(mut ctx Context, id string) veb.Result {
	dir_id := id.u32()
	if dir_id == 0 {
		return ctx.request_error('Invalid directory ID')
	}

	server.fs_factory.fs_dir.delete(dir_id) or {
		return ctx.server_error('Failed to delete directory: ${err}')
	}
	return ctx.success('', 'Directory deleted successfully')
}

// Create directory path
@['/api/dirs/create-path'; post]
pub fn (mut server FSServer) create_directory_path(mut ctx Context) veb.Result {
	path_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for path creation')
	}
	fs_id := path_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }.u32()
	path := path_data['path'] or { return ctx.request_error('Missing path field') }

	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	dir_id := server.fs_factory.fs_dir.create_path(fs_id, path) or {
		return ctx.server_error('Failed to create directory path: ${err}')
	}
	return ctx.success(dir_id, 'Directory path created successfully')
}

// Check if directory has children
@['/api/dirs/:id/has-children'; get]
pub fn (mut server FSServer) directory_has_children(mut ctx Context, id string) veb.Result {
	dir_id := id.u32()
	if dir_id == 0 {
		return ctx.request_error('Invalid directory ID')
	}

	has_children := server.fs_factory.fs_dir.has_children(dir_id) or {
		return ctx.server_error('Failed to check directory children: ${err}')
	}
	return ctx.success(has_children, 'Directory children status checked')
}

// Get directory children
@['/api/dirs/:id/children'; get]
pub fn (mut server FSServer) get_directory_children(mut ctx Context, id string) veb.Result {
	dir_id := id.u32()
	if dir_id == 0 {
		return ctx.request_error('Invalid directory ID')
	}

	children := server.fs_factory.fs_dir.list_children(dir_id) or {
		return ctx.server_error('Failed to get directory children: ${err}')
	}
	return ctx.success(children, 'Directory children retrieved successfully')
}

// List directories by filesystem
@['/api/dirs/by-filesystem/:fs_id'; get]
pub fn (mut server FSServer) list_directories_by_filesystem(mut ctx Context, fs_id string) veb.Result {
	filesystem_id := fs_id.u32()
	if filesystem_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	directories := server.fs_factory.fs_dir.list_by_filesystem(filesystem_id) or {
		return ctx.server_error('Failed to list directories by filesystem: ${err}')
	}
	return ctx.success(directories, 'Directories retrieved successfully')
}
