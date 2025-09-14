module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.herofs

// FSDir-specific argument structures
@[params]
pub struct FSDirGetArgs {
pub mut:
	id    u32
	path  string // Allow getting a directory by path
	fs_id u32    // Required when using path
}

@[params]
pub struct FSDirSetArgs {
pub mut:
	name        string @[required]
	fs_id       u32    @[required]
	parent_id   u32
	path        string // Allow creating directories by path
	description string
	metadata    map[string]string
}

@[params]
pub struct FSDirDeleteArgs {
pub mut:
	id    u32
	path  string // Allow deleting a directory by path
	fs_id u32    // Required when using path
}

@[params]
pub struct FSDirMoveArgs {
pub mut:
	id          u32
	parent_id   u32
	source_path string // Allow moving using paths
	dest_path   string
	fs_id       u32 // Required when using paths
}

@[params]
pub struct FSDirRenameArgs {
pub mut:
	id   u32    @[required]
	name string @[required]
}

@[params]
pub struct FSDirListByFilesystemArgs {
pub mut:
	fs_id u32 @[required]
}

@[params]
pub struct FSDirHasChildrenArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSDirListContentsArgs {
pub mut:
	dir_id    u32
	path      string // Allow listing contents by path
	fs_id     u32    // Required when using path
	recursive bool
	include   []string // Patterns to include
	exclude   []string // Patterns to exclude
}

pub fn fs_dir_get(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!

	// Handle either path-based or ID-based retrieval
	mut dir := if payload.path != '' && payload.fs_id > 0 {
		fs_factory.fs_dir.get_by_absolute_path(payload.fs_id, payload.path)!
	} else if payload.id > 0 {
		fs_factory.fs_dir.get(payload.id)!
	} else {
		return jsonrpc.invalid_params_with_msg('Either id or both path and fs_id must be provided')
	}

	return jsonrpc.new_response(request.id, json.encode(dir))
}

pub fn fs_dir_set(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!

	mut dir_id := u32(0)

	// Handle path-based creation
	if payload.path != '' {
		dir_id = fs_factory.fs_dir.create_path(payload.fs_id, payload.path)!
	} else {
		// Handle traditional creation
		mut dir_obj := fs_factory.fs_dir.new(
			name:        payload.name
			fs_id:       payload.fs_id
			parent_id:   payload.parent_id
			description: payload.description
			metadata:    payload.metadata
		)!
		dir_id = fs_factory.fs_dir.set(dir_obj)!
	}

	return new_response_u32(request.id, dir_id)
}

pub fn fs_dir_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!

	// Handle either path-based or ID-based deletion
	if payload.path != '' && payload.fs_id > 0 {
		fs_factory.fs_dir.delete_by_path(payload.fs_id, payload.path)!
	} else if payload.id > 0 {
		fs_factory.fs_dir.delete(payload.id)!
	} else {
		return jsonrpc.invalid_params_with_msg('Either id or both path and fs_id must be provided')
	}

	return new_response_true(request.id)
}

pub fn fs_dir_list(request Request) !Response {
	mut fs_factory := herofs.new()!
	dir_list := fs_factory.fs_dir.list()!

	return jsonrpc.new_response(request.id, json.encode(dir_list))
}

pub fn fs_dir_move(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirMoveArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!

	// Handle either path-based or ID-based move
	if payload.source_path != '' && payload.dest_path != '' && payload.fs_id > 0 {
		fs_factory.fs_dir.move_by_path(payload.fs_id, payload.source_path, payload.dest_path)!
	} else if payload.id > 0 && payload.parent_id > 0 {
		fs_factory.fs_dir.move(payload.id, payload.parent_id)!
	} else {
		return jsonrpc.invalid_params_with_msg('Either id and parent_id, or source_path, dest_path and fs_id must be provided')
	}

	return new_response_true(request.id)
}

pub fn fs_dir_rename(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirRenameArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs_dir.rename(payload.id, payload.name)!

	return new_response_true(request.id)
}

pub fn fs_dir_list_by_filesystem(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirListByFilesystemArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	dirs := fs_factory.fs_dir.list_by_filesystem(payload.fs_id)!

	return jsonrpc.new_response(request.id, json.encode(dirs))
}

pub fn fs_dir_has_children(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirHasChildrenArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	has_children := fs_factory.fs_dir.has_children(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(has_children))
}

// New method to list directory contents with filters
pub fn fs_dir_list_contents(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirListContentsArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!

	// Get directory ID either directly or from path
	mut dir_id := if payload.path != '' && payload.fs_id > 0 {
		dir := fs_factory.fs_dir.get_by_absolute_path(payload.fs_id, payload.path)!
		dir.id
	} else if payload.dir_id > 0 {
		payload.dir_id
	} else {
		return jsonrpc.invalid_params_with_msg('Either dir_id or both path and fs_id must be provided')
	}

	// Create options struct
	opts := herofs.ListContentsOptions{
		recursive:        payload.recursive
		include_patterns: payload.include
		exclude_patterns: payload.exclude
	}

	// List contents with filters
	contents := fs_factory.fs_dir.list_contents(&fs_factory, dir_id, opts)!

	return jsonrpc.new_response(request.id, json.encode(contents))
}
