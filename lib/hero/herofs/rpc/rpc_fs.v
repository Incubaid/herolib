module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.herofs

// FS-specific argument structures
@[params]
pub struct FSGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSSetArgs {
pub mut:
	name        string @[required]
	description string
	quota_bytes u64
	root_dir_id u32
}

@[params]
pub struct FSDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn fs_get(request Request) !Response {
	payload := jsonrpc.decode_payload[FSGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs := fs_factory.fs.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(fs))
}

pub fn fs_set(request Request) !Response {
	payload := jsonrpc.decode_payload[FSSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	mut fs_obj := fs_factory.fs.new(
		name: payload.name
		description: payload.description
		quota_bytes: payload.quota_bytes
	)!
	
	if payload.root_dir_id > 0 {
		fs_obj.root_dir_id = payload.root_dir_id
	}

	id := fs_factory.fs.set(fs_obj)!

	return new_response_u32(request.id, id)
}

pub fn fs_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[FSDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs.delete(payload.id)!

	return new_response_true(request.id)
}

pub fn fs_list(request Request) !Response {
	mut fs_factory := herofs.new()!
	fs_list := fs_factory.fs.list()!

	return jsonrpc.new_response(request.id, json.encode(fs_list))
}
