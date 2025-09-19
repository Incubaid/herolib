module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels

// RegistrationDesk-specific argument structures
@[params]
pub struct RegistrationDeskGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct RegistrationDeskSetArgs {
pub mut:
	name               string
	description        string
	fs_items           []u32
	white_list         []u32
	white_list_accepted []u32
	black_list         []u32
	start_time         string
	end_time           string
	acceptance_required bool
	securitypolicy     u32
	tags               []string
	messages           []heromodels.db.MessageArg
}

@[params]
pub struct RegistrationDeskDeleteArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct RegistrationDeskListArgs {
pub mut:
	name        string
	description string
	limit       int = 100
}

pub fn registration_desk_get(request Request) !Response {
	payload := jsonrpc.decode_payload[RegistrationDeskGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	registration_desk := mydb.registration_desks.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(registration_desk))
}

pub fn registration_desk_set(request Request) !Response {
	payload := jsonrpc.decode_payload[RegistrationDeskSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut registration_desk_obj := mydb.registration_desks.new(
		name:                payload.name
		description:         payload.description
		fs_items:            payload.fs_items
		white_list:          payload.white_list
		white_list_accepted: payload.white_list_accepted
		black_list:          payload.black_list
		start_time:          payload.start_time
		end_time:            payload.end_time
		acceptance_required: payload.acceptance_required
		securitypolicy:      payload.securitypolicy
		tags:                payload.tags
		messages:            payload.messages
	)!

	registration_desk_obj = mydb.registration_desks.set(registration_desk_obj)!

	return new_response_u32(request.id, registration_desk_obj.id)
}

pub fn registration_desk_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[RegistrationDeskDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.registration_desks.delete(payload.id)!

	return new_response_true(request.id)
}

pub fn registration_desk_exist(request Request) !Response {
	payload := jsonrpc.decode_payload[RegistrationDeskGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	exists := mydb.registration_desks.exist(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(exists))
}

pub fn registration_desk_list(request Request) !Response {
	payload := jsonrpc.decode_payload[RegistrationDeskListArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	registration_desks := mydb.registration_desks.list(
		name:        payload.name
		description: payload.description
		limit:       payload.limit
	)!

	return jsonrpc.new_response(request.id, json.encode(registration_desks))
}