module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.hero.db
// ChatGroup-specific argument structures

@[params]
pub struct ChatGroupGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct ChatGroupSetArgs {
pub mut:
	name           string
	description    string
	chat_type      heromodels.ChatType
	last_activity  i64
	is_archived    bool
	securitypolicy u32
	tags           []string
	messages       []db.MessageArg
}

@[params]
pub struct ChatGroupDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn chat_group_get(request Request) !Response {
	payload := jsonrpc.decode_payload[ChatGroupGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	chat_group := mydb.chat_group.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(chat_group))
}

pub fn chat_group_set(request Request) !Response {
	payload := jsonrpc.decode_payload[ChatGroupSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut chat_group_obj := mydb.chat_group.new(
		name:           payload.name
		description:    payload.description
		chat_type:      payload.chat_type
		last_activity:  payload.last_activity
		is_archived:    payload.is_archived
		securitypolicy: payload.securitypolicy
		tags:           payload.tags
		messages:       payload.messages
	)!

	chat_group_obj=mydb.chat_group.set( chat_group_obj)!

	return new_response_u32(request.id, chat_group_obj.id)
}

pub fn chat_group_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[ChatGroupDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.chat_group.delete(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn chat_group_list(request Request) !Response {
	mut mydb := heromodels.new()!
	chat_groups := mydb.chat_group.list()!

	return jsonrpc.new_response(request.id, json.encode(chat_groups))
}
