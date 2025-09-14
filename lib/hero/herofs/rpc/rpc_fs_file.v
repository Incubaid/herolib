module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.herofs

// FSFile-specific argument structures
@[params]
pub struct FSFileGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSFileSetArgs {
pub mut:
	name        string @[required]
	fs_id       u32    @[required]
	directories []u32
	blobs       []u32
	mime_type   string
	metadata    map[string]string
}

@[params]
pub struct FSFileDeleteArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSFileMoveArgs {
pub mut:
	id          u32   @[required]
	directories []u32 @[required]
}

@[params]
pub struct FSFileRenameArgs {
pub mut:
	id   u32    @[required]
	name string @[required]
}

@[params]
pub struct FSFileUpdateMetadataArgs {
pub mut:
	id    u32    @[required]
	key   string @[required]
	value string @[required]
}

@[params]
pub struct FSFileUpdateAccessedArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct FSFileAppendBlobArgs {
pub mut:
	id      u32 @[required]
	blob_id u32 @[required]
}

@[params]
pub struct FSFileListByDirectoryArgs {
pub mut:
	directory_id u32 @[required]
}

@[params]
pub struct FSFileListByFilesystemArgs {
pub mut:
	fs_id u32 @[required]
}

@[params]
pub struct FSFileListByMimeTypeArgs {
pub mut:
	mime_type string @[required]
}

pub fn fs_file_get(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	file := fs_factory.fs_file.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(file))
}

pub fn fs_file_set(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	mut file_obj := fs_factory.fs_file.new(
		name:        payload.name
		fs_id:       payload.fs_id
		directories: payload.directories
		blobs:       payload.blobs
		mime_type:   payload.mime_type
		metadata:    payload.metadata
	)!

	id := fs_factory.fs_file.set(file_obj)!

	return new_response_u32(request.id, id)
}

pub fn fs_file_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs_file.delete(payload.id)!

	return new_response_true(request.id)
}

pub fn fs_file_list(request Request) !Response {
	mut fs_factory := herofs.new()!
	file_list := fs_factory.fs_file.list()!

	return jsonrpc.new_response(request.id, json.encode(file_list))
}

pub fn fs_file_move(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileMoveArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs_file.move(payload.id, payload.directories)!

	return new_response_true(request.id)
}

pub fn fs_file_rename(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileRenameArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs_file.rename(payload.id, payload.name)!

	return new_response_true(request.id)
}

pub fn fs_file_update_metadata(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileUpdateMetadataArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs_file.update_metadata(payload.id, payload.key, payload.value)!

	return new_response_true(request.id)
}

pub fn fs_file_update_accessed(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileUpdateAccessedArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs_file.update_accessed(payload.id)!

	return new_response_true(request.id)
}

pub fn fs_file_append_blob(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileAppendBlobArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	fs_factory.fs_file.append_blob(payload.id, payload.blob_id)!

	return new_response_true(request.id)
}

pub fn fs_file_list_by_directory(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileListByDirectoryArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	files := fs_factory.fs_file.list_by_directory(payload.directory_id)!

	return jsonrpc.new_response(request.id, json.encode(files))
}

pub fn fs_file_list_by_filesystem(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileListByFilesystemArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	files := fs_factory.fs_file.list_by_filesystem(payload.fs_id)!

	return jsonrpc.new_response(request.id, json.encode(files))
}

pub fn fs_file_list_by_mime_type(request Request) !Response {
	payload := jsonrpc.decode_payload[FSFileListByMimeTypeArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut fs_factory := herofs.new()!
	files := fs_factory.fs_file.list_by_mime_type(payload.mime_type)!

	return jsonrpc.new_response(request.id, json.encode(files))
}
