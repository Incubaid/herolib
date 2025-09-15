module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels

// Group-specific argument structures
@[params]
pub struct GroupGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct GroupSetArgs {
pub mut:
	name         string
	description  string
	members      []heromodels.GroupMember
	subgroups    []u32
	parent_group u32
	is_public    bool
}

@[params]
pub struct GroupDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn group_get(request Request) !Response {
	payload := jsonrpc.decode_payload[GroupGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	group := mydb.group.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(group))
}

pub fn group_set(request Request) !Response {
	payload := jsonrpc.decode_payload[GroupSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut group_obj := mydb.group.new(
		name:         payload.name
		description:  payload.description
		members:      payload.members
		subgroups:    payload.subgroups
		parent_group: payload.parent_group
		is_public:    payload.is_public
	)!

	mydb.group.set(mut group_obj)!

	return new_response_u32(request.id, group_obj.id)
}

pub fn group_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[GroupDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.group.delete(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn group_list(request Request) !Response {
	mut mydb := heromodels.new()!
	groups := mydb.group.list()!

	return jsonrpc.new_response(request.id, json.encode(groups))
}
