module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.herofs
import encoding.base64

// FSBlob-specific argument structures
@[params]
pub struct FSBlobGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSBlobSetArgs {
pub mut:
	data_base64 string @[required] // Base64-encoded data
	mime_type   string
	name        string
}

@[params]
pub struct FSBlobDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn fs_blob_get(request Request) !Response {
	payload := jsonrpc.decode_payload[FSBlobGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	blob := fs_factory.fs_blob.get(payload.id)!
	
	// Convert binary data to base64 for JSON transport
	blob_response := {
		'id': blob.id.str()
		'created_at': blob.created_at.str()
		'updated_at': blob.updated_at.str()
		'mime_type': blob.mime_type
		'name': blob.name
		'hash': blob.hash
		'size_bytes': blob.size_bytes.str()
		'data_base64': base64.encode(blob.data)
	}

	return jsonrpc.new_response(request.id, json.encode(blob_response))
}

pub fn fs_blob_set(request Request) !Response {
	payload := jsonrpc.decode_payload[FSBlobSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	// Decode the base64 data
	data := base64.decode(payload.data_base64) or {
		return jsonrpc.invalid_params_with_msg("Invalid base64 data")
	}

	mut fs_factory := herofs.new()!
	mut blob_obj := fs_factory.fs_blob.new(
		data: data
		mime_type: payload.mime_type
		name: payload.name
	)!

	id := fs_factory.fs_blob.set(blob_obj)!

	return new_response_u32(request.id, id)
}

pub fn fs_blob_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[FSBlobDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs_blob.delete(payload.id)!

	return new_response_true(request.id)
}

pub fn fs_blob_list(request Request) !Response {
	mut fs_factory := herofs.new()!
	blob_list := fs_factory.fs_blob.list()!
	
	// Convert binary data to base64 for each blob
	mut blob_responses := []map[string]string{}
	for blob in blob_list {
		blob_responses << {
			'id': blob.id.str()
			'created_at': blob.created_at.str()
			'updated_at': blob.updated_at.str()
			'mime_type': blob.mime_type
			'name': blob.name
			'hash': blob.hash
			'size_bytes': blob.size_bytes.str()
			'data_base64': base64.encode(blob.data)
		}
	}

	return jsonrpc.new_response(request.id, json.encode(blob_responses))
}
