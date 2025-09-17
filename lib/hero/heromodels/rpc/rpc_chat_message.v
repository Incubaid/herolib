module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.hero.db
// ChatMessage-specific argument structures

@[params]
pub struct ChatMessageGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct ChatMessageSetArgs {
pub mut:
	name            string
	description     string
	content         string
	chat_group_id   u32
	sender_id       u32
	parent_messages []heromodels.MessageLink
	fs_files        []u32
	message_type    heromodels.MessageType
	status          heromodels.MessageStatus
	reactions       []heromodels.MessageReaction
	mentions        []u32
	securitypolicy  u32
	tags            []string
	comments        []db.CommentArg
}

@[params]
pub struct ChatMessageDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn chat_message_get(request Request) !Response {
	payload := jsonrpc.decode_payload[ChatMessageGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	chat_message := mydb.chat_message.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(chat_message))
}

pub fn chat_message_set(request Request) !Response {
	payload := jsonrpc.decode_payload[ChatMessageSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut chat_message_obj := mydb.chat_message.new(
		name:            payload.name
		description:     payload.description
		content:         payload.content
		chat_group_id:   payload.chat_group_id
		sender_id:       payload.sender_id
		parent_messages: payload.parent_messages
		fs_files:        payload.fs_files
		message_type:    payload.message_type
		status:          payload.status
		reactions:       payload.reactions
		mentions:        payload.mentions
		securitypolicy:  payload.securitypolicy
		tags:            payload.tags
		comments:        payload.comments
	)!

	chat_message_obj=mydb.chat_message.set( chat_message_obj)!

	return new_response_u32(request.id, chat_message_obj.id)
}

pub fn chat_message_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[ChatMessageDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.chat_message.delete(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn chat_message_list(request Request) !Response {
	mut mydb := heromodels.new()!
	chat_messages := mydb.chat_message.list()!

	return jsonrpc.new_response(request.id, json.encode(chat_messages))
}
