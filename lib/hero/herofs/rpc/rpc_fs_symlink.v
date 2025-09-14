module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.herofs

// FSSymlink-specific argument structures
@[params]
pub struct FSSymlinkGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSSymlinkSetArgs {
pub mut:
	name        string @[required]
	fs_id       u32    @[required]
	parent_id   u32    @[required]
	target_id   u32    @[required]
	target_type string @[required] // "file" or "directory"
	description string
}

@[params]
pub struct FSSymlinkDeleteArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSSymlinkIsBrokenArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSSymlinkListByFilesystemArgs {
pub mut:
	fs_id u32 @[required]
}

pub fn fs_symlink_get(request Request) !Response {
	payload := jsonrpc.decode_payload[FSSymlinkGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	symlink := fs_factory.fs_symlink.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(symlink))
}

pub fn fs_symlink_set(request Request) !Response {
	payload := jsonrpc.decode_payload[FSSymlinkSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	// Convert target_type string to enum
	target_type := match payload.target_type.to_lower() {
		'file' { herofs.SymlinkTargetType.file }
		'directory' { herofs.SymlinkTargetType.directory }
		else { return jsonrpc.invalid_params_with_msg("target_type must be 'file' or 'directory'") }
	}

	mut fs_factory := herofs.new()!
	mut symlink_obj := fs_factory.fs_symlink.new(
		name: payload.name
		fs_id: payload.fs_id
		parent_id: payload.parent_id
		target_id: payload.target_id
		target_type: target_type
		description: payload.description
	)!

	id := fs_factory.fs_symlink.set(symlink_obj)!

	return new_response_u32(request.id, id)
}

pub fn fs_symlink_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[FSSymlinkDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs_symlink.delete(payload.id)!

	return new_response_true(request.id)
}

pub fn fs_symlink_list(request Request) !Response {
	mut fs_factory := herofs.new()!
	symlink_list := fs_factory.fs_symlink.list()!

	return jsonrpc.new_response(request.id, json.encode(symlink_list))
}

pub fn fs_symlink_is_broken(request Request) !Response {
	payload := jsonrpc.decode_payload[FSSymlinkIsBrokenArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	is_broken := fs_factory.fs_symlink.is_broken(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(is_broken))
}

pub fn fs_symlink_list_by_filesystem(request Request) !Response {
	payload := jsonrpc.decode_payload[FSSymlinkListByFilesystemArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	symlinks := fs_factory.fs_symlink.list_by_filesystem(payload.fs_id)!

	return jsonrpc.new_response(request.id, json.encode(symlinks))
}
