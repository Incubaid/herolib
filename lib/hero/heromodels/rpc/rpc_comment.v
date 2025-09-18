module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels

// Message-specific argument structures
@[params]
pub struct MessageGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct MessageSetArgs {
pub mut:
	message string @[required]
	parent  u32
	author  u32
}

@[params]
pub struct MessageDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn message_get(request Request) !Response {
	payload := jsonrpc.decode_payload[MessageGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	message := mydb.messages.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(message))
}

pub fn message_set(request Request) !Response {
	payload := jsonrpc.decode_payload[MessageSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut message_obj := mydb.messages.new(
		message: payload.message
		parent:  payload.parent
		author:  payload.author
	)!

	message_obj=mydb.messages.set( message_obj)!

	return new_response_u32(request.id, message_obj.id)
}

pub fn message_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[MessageDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.messages.delete(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn message_list(request Request) !Response {
	mut mydb := heromodels.new()!
	messages := mydb.messages.list()!

	return jsonrpc.new_response(request.id, json.encode(messages))
}
