module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels

// Comment-specific argument structures
@[params]
pub struct CommentGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct CommentSetArgs {
pub mut:
	comment string @[required]
	parent  u32
	author  u32
}

@[params]
pub struct CommentDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn comment_get(request Request) !Response {
	payload := jsonrpc.decode_payload[CommentGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	comment := mydb.comments.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(comment))
}

pub fn comment_set(request Request) !Response {
	payload := jsonrpc.decode_payload[CommentSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut comment_obj := mydb.comments.new(
		comment: payload.comment
		parent:  payload.parent
		author:  payload.author
	)!

	id := mydb.comments.set(comment_obj)!

	return new_response_u32(request.id, id)
}

pub fn comment_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[CommentDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.comments.delete(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn comment_list(request Request) !Response {
	mut mydb := heromodels.new()!
	comments := mydb.comments.list()!

	return jsonrpc.new_response(request.id, json.encode(comments))
}
