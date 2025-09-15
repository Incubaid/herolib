module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.herofs
import encoding.base64

// FSBlob-specific argument structures
@[params]
pub struct FSBlobGetArgs {
pub mut:
	id   u32
	hash string
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

	// Get blob by either id or hash
	mut blob := if payload.id > 0 {
		fs_factory.fs_blob.get(payload.id)!
	} else if payload.hash != '' {
		fs_factory.fs_blob.get_by_hash(payload.hash)!
	} else {
		return jsonrpc.invalid_params_with_msg('Either id or hash must be provided')
	}

	// Convert binary data to base64 for JSON transport
	blob_response := {
		'id':          blob.id.str()
		'updated_at':  blob.updated_at.str()
		'mime_type':   blob.mime_type.str()
		'name':        blob.name
		'hash':        blob.hash
		'size_bytes':  blob.size_bytes.str()
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
		return jsonrpc.invalid_params_with_msg('Invalid base64 data')
	}

	// Convert MIME type string to enum
	mime_type := herofs.string_to_mime_type(payload.mime_type) or {
		return jsonrpc.invalid_params_with_msg('Invalid MIME type: ${payload.mime_type}')
	}

	mut fs_factory := herofs.new()!
	mut blob_obj := fs_factory.fs_blob.new(
		data:      data
		mime_type: mime_type
		name:      payload.name
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
