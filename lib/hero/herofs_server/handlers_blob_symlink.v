module herofs_server

import veb
import json
import incubaid.herolib.hero.herofs

// =============================================================================
// BLOB ENDPOINTS
// =============================================================================

// List all blobs
@['/api/blobs'; get]
pub fn (mut server FSServer) list_blobs(mut ctx Context) veb.Result {
	blob_ids := server.fs_factory.fs_blob.db.list[herofs.FsBlob]() or {
		return ctx.server_error('Failed to list blob IDs: ${err}')
	}
	mut blobs := []herofs.FsBlob{}
	for id in blob_ids {
		blob := server.fs_factory.fs_blob.get(id) or { continue }
		blobs << blob
	}
	return ctx.success(blobs, 'Blobs retrieved successfully')
}

// Get blob by ID
@['/api/blobs/:id'; get]
pub fn (mut server FSServer) get_blob(mut ctx Context, id string) veb.Result {
	blob_id := id.u32()
	if blob_id == 0 {
		return ctx.request_error('Invalid blob ID')
	}

	blob := server.fs_factory.fs_blob.get(blob_id) or { return ctx.not_found('Blob not found') }
	return ctx.success(blob, 'Blob retrieved successfully')
}

// Create new blob
@['/api/blobs'; post]
pub fn (mut server FSServer) create_blob(mut ctx Context) veb.Result {
	blob_args := json.decode(herofs.FsBlobArg, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for blob creation')
	}

	mut blob := server.fs_factory.fs_blob.new(blob_args) or {
		return ctx.server_error('Failed to create blob: ${err}')
	}
	blob = server.fs_factory.fs_blob.set(blob) or {
		return ctx.server_error('Failed to save blob: ${err}')
	}

	return ctx.created(blob, 'Blob created successfully')
}

// Update blob
@['/api/blobs/:id'; put]
pub fn (mut server FSServer) update_blob(mut ctx Context, id string) veb.Result {
	blob_id := id.u32()
	if blob_id == 0 {
		return ctx.request_error('Invalid blob ID')
	}

	mut blob := json.decode(herofs.FsBlob, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for blob update')
	}
	blob.id = blob_id

	blob = server.fs_factory.fs_blob.set(blob) or {
		return ctx.server_error('Failed to update blob: ${err}')
	}
	return ctx.success(blob, 'Blob updated successfully')
}

// Delete blob
@['/api/blobs/:id'; delete]
pub fn (mut server FSServer) delete_blob(mut ctx Context, id string) veb.Result {
	blob_id := id.u32()
	if blob_id == 0 {
		return ctx.request_error('Invalid blob ID')
	}

	server.fs_factory.fs_blob.delete(blob_id) or {
		return ctx.server_error('Failed to delete blob: ${err}')
	}
	return ctx.success('', 'Blob deleted successfully')
}

// Get blob content (raw data)
@['/api/blobs/:id/content'; get]
pub fn (mut server FSServer) get_blob_content(mut ctx Context, id string) veb.Result {
	blob_id := id.u32()
	if blob_id == 0 {
		return ctx.request_error('Invalid blob ID')
	}

	blob := server.fs_factory.fs_blob.get(blob_id) or { return ctx.not_found('Blob not found') }

	// Set appropriate content type
	if blob.mime_type.len > 0 {
		ctx.set_content_type(blob.mime_type)
	} else {
		ctx.set_content_type('application/octet-stream')
	}

	return ctx.text(blob.data.bytestr())
}

// Verify blob integrity
@['/api/blobs/:id/verify'; get]
pub fn (mut server FSServer) verify_blob_integrity(mut ctx Context, id string) veb.Result {
	blob_id := id.u32()
	if blob_id == 0 {
		return ctx.request_error('Invalid blob ID')
	}

	blob := server.fs_factory.fs_blob.get(blob_id) or { return ctx.not_found('Blob not found') }
	is_valid := blob.verify_integrity()

	return ctx.success(is_valid, 'Blob integrity verified')
}

// Get blob by hash
@['/api/blobs/by-hash/:hash'; get]
pub fn (mut server FSServer) get_blob_by_hash(mut ctx Context, hash string) veb.Result {
	if hash == '' {
		return ctx.request_error('Invalid blob hash')
	}

	blob := server.fs_factory.fs_blob.get_by_hash(hash) or {
		return ctx.not_found('Blob not found')
	}
	return ctx.success(blob, 'Blob retrieved successfully')
}

// Check if blob exists by hash
@['/api/blobs/exists-by-hash/:hash'; get]
pub fn (mut server FSServer) blob_exists_by_hash(mut ctx Context, hash string) veb.Result {
	if hash == '' {
		return ctx.request_error('Invalid blob hash')
	}

	exists := server.fs_factory.fs_blob.exists_by_hash(hash) or {
		return ctx.server_error('Failed to check blob existence: ${err}')
	}
	return ctx.success(exists, 'Blob existence checked')
}

// =============================================================================
// SYMLINK ENDPOINTS
// =============================================================================

// List all symlinks
@['/api/symlinks'; get]
pub fn (mut server FSServer) list_symlinks(mut ctx Context) veb.Result {
	symlinks := server.fs_factory.fs_symlink.list() or {
		return ctx.server_error('Failed to list symlinks: ${err}')
	}
	return ctx.success(symlinks, 'Symlinks retrieved successfully')
}

// Get symlink by ID
@['/api/symlinks/:id'; get]
pub fn (mut server FSServer) get_symlink(mut ctx Context, id string) veb.Result {
	symlink_id := id.u32()
	if symlink_id == 0 {
		return ctx.request_error('Invalid symlink ID')
	}

	symlink := server.fs_factory.fs_symlink.get(symlink_id) or {
		return ctx.not_found('Symlink not found')
	}
	return ctx.success(symlink, 'Symlink retrieved successfully')
}

// Create new symlink
@['/api/symlinks'; post]
pub fn (mut server FSServer) create_symlink(mut ctx Context) veb.Result {
	symlink_args := json.decode(herofs.FsSymlinkArg, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for symlink creation')
	}

	mut symlink := server.fs_factory.fs_symlink.new(symlink_args) or {
		return ctx.server_error('Failed to create symlink: ${err}')
	}
	symlink = server.fs_factory.fs_symlink.set(symlink) or {
		return ctx.server_error('Failed to save symlink: ${err}')
	}

	return ctx.created(symlink, 'Symlink created successfully')
}

// Update symlink
@['/api/symlinks/:id'; put]
pub fn (mut server FSServer) update_symlink(mut ctx Context, id string) veb.Result {
	symlink_id := id.u32()
	if symlink_id == 0 {
		return ctx.request_error('Invalid symlink ID')
	}

	mut symlink := json.decode(herofs.FsSymlink, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for symlink update')
	}
	symlink.id = symlink_id

	symlink = server.fs_factory.fs_symlink.set(symlink) or {
		return ctx.server_error('Failed to update symlink: ${err}')
	}
	return ctx.success(symlink, 'Symlink updated successfully')
}

// Delete symlink
@['/api/symlinks/:id'; delete]
pub fn (mut server FSServer) delete_symlink(mut ctx Context, id string) veb.Result {
	symlink_id := id.u32()
	if symlink_id == 0 {
		return ctx.request_error('Invalid symlink ID')
	}

	server.fs_factory.fs_symlink.delete(symlink_id) or {
		return ctx.server_error('Failed to delete symlink: ${err}')
	}
	return ctx.success('', 'Symlink deleted successfully')
}

// List symlinks by filesystem
@['/api/symlinks/by-filesystem/:fs_id'; get]
pub fn (mut server FSServer) list_symlinks_by_filesystem(mut ctx Context, fs_id string) veb.Result {
	filesystem_id := fs_id.u32()
	if filesystem_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	symlinks := server.fs_factory.fs_symlink.list_by_filesystem(filesystem_id) or {
		return ctx.server_error('Failed to list symlinks by filesystem: ${err}')
	}
	return ctx.success(symlinks, 'Symlinks retrieved successfully')
}

// Check if symlink is broken
@['/api/symlinks/:id/is-broken'; get]
pub fn (mut server FSServer) check_symlink_broken(mut ctx Context, id string) veb.Result {
	symlink_id := id.u32()
	if symlink_id == 0 {
		return ctx.request_error('Invalid symlink ID')
	}

	is_broken := server.fs_factory.fs_symlink.is_broken(symlink_id) or {
		return ctx.server_error('Failed to check symlink status: ${err}')
	}
	return ctx.success(is_broken, 'Symlink status checked')
}

// Check if symlink is broken
@['/api/symlinks/:id/is-broken'; get]
pub fn (mut server FSServer) symlink_is_broken(mut ctx Context, id string) veb.Result {
	symlink_id := id.u32()
	if symlink_id == 0 {
		return ctx.request_error('Invalid symlink ID')
	}

	is_broken := server.fs_factory.fs_symlink.is_broken(symlink_id) or {
		return ctx.server_error('Failed to check symlink status: ${err}')
	}
	return ctx.success(is_broken, 'Symlink status checked')
}

// =============================================================================
// BLOB MEMBERSHIP ENDPOINTS
// =============================================================================

// List all blob memberships
@['/api/blob-membership'; get]
pub fn (mut server FSServer) list_blob_memberships(mut ctx Context) veb.Result {
	// Get all blob membership hashes from Redis
	hashes := server.fs_factory.fs_blob_membership.db.redis.hkeys('fs_blob_membership') or {
		return ctx.server_error('Failed to list blob membership hashes: ${err}')
	}
	mut memberships := []herofs.FsBlobMembership{}
	for hash in hashes {
		membership := server.fs_factory.fs_blob_membership.get(hash) or { continue }
		memberships << membership
	}
	return ctx.success(memberships, 'Blob memberships retrieved successfully')
}

// Get blob membership by hash
@['/api/blob-membership/:hash'; get]
pub fn (mut server FSServer) get_blob_membership(mut ctx Context, hash string) veb.Result {
	if hash == '' {
		return ctx.request_error('Invalid membership hash')
	}

	membership := server.fs_factory.fs_blob_membership.get(hash) or {
		return ctx.not_found('Blob membership not found')
	}
	return ctx.success(membership, 'Blob membership retrieved successfully')
}

// Create new blob membership
@['/api/blob-membership'; post]
pub fn (mut server FSServer) create_blob_membership(mut ctx Context) veb.Result {
	membership_args := json.decode(herofs.FsBlobMembershipArg, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for blob membership creation')
	}

	mut membership := server.fs_factory.fs_blob_membership.new(membership_args) or {
		return ctx.server_error('Failed to create blob membership: ${err}')
	}
	membership = server.fs_factory.fs_blob_membership.set(membership) or {
		return ctx.server_error('Failed to save blob membership: ${err}')
	}

	return ctx.created(membership, 'Blob membership created successfully')
}

// Delete blob membership
@['/api/blob-membership/:hash'; delete]
pub fn (mut server FSServer) delete_blob_membership(mut ctx Context, hash string) veb.Result {
	if hash == '' {
		return ctx.request_error('Invalid blob membership hash')
	}

	server.fs_factory.fs_blob_membership.delete(hash) or {
		return ctx.server_error('Failed to delete blob membership: ${err}')
	}
	return ctx.success('', 'Blob membership deleted successfully')
}

// Add filesystem to blob membership
@['/api/blob-membership/:hash/add-filesystem'; post]
pub fn (mut server FSServer) add_filesystem_to_blob_membership(mut ctx Context, hash string) veb.Result {
	if hash == '' {
		return ctx.request_error('Invalid blob membership hash')
	}

	fs_data := json.decode(map[string]u32, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for filesystem data')
	}
	fs_id := fs_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }

	server.fs_factory.fs_blob_membership.add_filesystem(hash, fs_id) or {
		return ctx.server_error('Failed to add filesystem to blob membership: ${err}')
	}
	return ctx.success('', 'Filesystem added to blob membership successfully')
}

// Remove filesystem from blob membership
@['/api/blob-membership/:hash/remove-filesystem'; post]
pub fn (mut server FSServer) remove_filesystem_from_blob_membership(mut ctx Context, hash string) veb.Result {
	if hash == '' {
		return ctx.request_error('Invalid blob membership hash')
	}

	fs_data := json.decode(map[string]u32, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for filesystem data')
	}
	fs_id := fs_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }

	server.fs_factory.fs_blob_membership.remove_filesystem(hash, fs_id) or {
		return ctx.server_error('Failed to remove filesystem from blob membership: ${err}')
	}
	return ctx.success('', 'Filesystem removed from blob membership successfully')
}
