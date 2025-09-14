module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.herofs

// FSDir-specific argument structures
@[params]
pub struct FSDirGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSDirSetArgs {
pub mut:
	name        string @[required]
	fs_id       u32    @[required]
	parent_id   u32
	description string
	metadata    map[string]string
}

@[params]
pub struct FSDirDeleteArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSDirMoveArgs {
pub mut:
	id        u32 @[required]
	parent_id u32 @[required]
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

pub fn fs_dir_get(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	dir := fs_factory.fs_dir.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(dir))
}

pub fn fs_dir_set(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	mut dir_obj := fs_factory.fs_dir.new(
		name: payload.name
		fs_id: payload.fs_id
		parent_id: payload.parent_id
		description: payload.description
		metadata: payload.metadata
	)!

	id := fs_factory.fs_dir.set(dir_obj)!

	return new_response_u32(request.id, id)
}

pub fn fs_dir_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDirDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs_dir.delete(payload.id)!

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
	fs_factory.fs_dir.move(payload.id, payload.parent_id)!

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
