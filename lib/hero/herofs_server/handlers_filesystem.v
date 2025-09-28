module herofs_server

import veb
import json
import freeflowuniverse.herolib.hero.herofs

// =============================================================================
// FILESYSTEM ENDPOINTS
// =============================================================================

// List all filesystems
@['/api/fs'; get]
pub fn (mut server FSServer) list_filesystems(mut ctx Context) veb.Result {
	filesystems := server.fs_factory.fs.list() or {
		return ctx.server_error('Failed to list filesystems: ${err}')
	}
	return ctx.success(filesystems, 'Filesystems retrieved successfully')
}

// Get filesystem by ID
@['/api/fs/:id'; get]
pub fn (mut server FSServer) get_filesystem(mut ctx Context, id string) veb.Result {
	fs_id := id.u32()
	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	filesystem := server.fs_factory.fs.get(fs_id) or {
		return ctx.not_found('Filesystem not found')
	}
	return ctx.success(filesystem, 'Filesystem retrieved successfully')
}

// Create new filesystem
@['/api/fs'; post]
pub fn (mut server FSServer) create_filesystem(mut ctx Context) veb.Result {
	fs_args := json.decode(herofs.FsArg, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for filesystem creation')
	}

	mut filesystem := server.fs_factory.fs.new(fs_args) or {
		return ctx.server_error('Failed to create filesystem: ${err}')
	}
	filesystem = server.fs_factory.fs.set(filesystem) or {
		return ctx.server_error('Failed to save filesystem: ${err}')
	}

	return ctx.created(filesystem, 'Filesystem created successfully')
}

// Update filesystem
@['/api/fs/:id'; put]
pub fn (mut server FSServer) update_filesystem(mut ctx Context, id string) veb.Result {
	fs_id := id.u32()
	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	mut filesystem := json.decode(herofs.Fs, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for filesystem update')
	}
	filesystem.id = fs_id

	filesystem = server.fs_factory.fs.set(filesystem) or {
		return ctx.server_error('Failed to update filesystem: ${err}')
	}
	return ctx.success(filesystem, 'Filesystem updated successfully')
}

// Delete filesystem
@['/api/fs/:id'; delete]
pub fn (mut server FSServer) delete_filesystem(mut ctx Context, id string) veb.Result {
	fs_id := id.u32()
	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	server.fs_factory.fs.delete(fs_id) or {
		return ctx.server_error('Failed to delete filesystem: ${err}')
	}
	return ctx.success('', 'Filesystem deleted successfully')
}

// Check if filesystem exists
@['/api/fs/:id/exists'; get]
pub fn (mut server FSServer) filesystem_exists(mut ctx Context, id string) veb.Result {
	fs_id := id.u32()
	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	exists := server.fs_factory.fs.exist(fs_id) or {
		return ctx.server_error('Failed to check filesystem existence: ${err}')
	}
	return ctx.success(exists, 'Filesystem existence checked')
}

// Increase filesystem usage
@['/api/fs/:id/usage/increase'; post]
pub fn (mut server FSServer) increase_filesystem_usage(mut ctx Context, id string) veb.Result {
	fs_id := id.u32()
	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	usage_data := json.decode(map[string]u64, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for usage data')
	}
	bytes := usage_data['bytes'] or { return ctx.request_error('Missing bytes field') }

	server.fs_factory.fs.increase_usage(fs_id, bytes) or {
		return ctx.server_error('Failed to increase filesystem usage: ${err}')
	}
	return ctx.success('', 'Filesystem usage increased successfully')
}

// Decrease filesystem usage
@['/api/fs/:id/usage/decrease'; post]
pub fn (mut server FSServer) decrease_filesystem_usage(mut ctx Context, id string) veb.Result {
	fs_id := id.u32()
	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	usage_data := json.decode(map[string]u64, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for usage data')
	}
	bytes := usage_data['bytes'] or { return ctx.request_error('Missing bytes field') }

	server.fs_factory.fs.decrease_usage(fs_id, bytes) or {
		return ctx.server_error('Failed to decrease filesystem usage: ${err}')
	}
	return ctx.success('', 'Filesystem usage decreased successfully')
}

// Check filesystem quota
@['/api/fs/:id/quota/check'; post]
pub fn (mut server FSServer) check_filesystem_quota(mut ctx Context, id string) veb.Result {
	fs_id := id.u32()
	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	quota_data := json.decode(map[string]u64, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for quota data')
	}
	bytes := quota_data['bytes'] or { return ctx.request_error('Missing bytes field') }

	can_add := server.fs_factory.fs.check_quota(fs_id, bytes) or {
		return ctx.server_error('Failed to check filesystem quota: ${err}')
	}
	return ctx.success(can_add, 'Filesystem quota checked')
}
