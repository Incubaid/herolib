module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels

// User-specific argument structures
@[params]
pub struct UserGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct UserSetArgs {
pub mut:
	name           string @[required]
	description    string
	email          string
	public_key     string // for encryption/signing
	phone          string
	address        string
	avatar_url     string
	bio            string
	timezone       string
	status         heromodels.UserStatus
	securitypolicy u32
	tags           u32
	comments       []u32
}

@[params]
pub struct UserDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn user_get(request Request) !Response {
	payload := jsonrpc.decode_payload[UserGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	user := mydb.user.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(user))
}

pub fn user_set(request Request) !Response {
	payload := jsonrpc.decode_payload[UserSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut user_obj := mydb.user.new(
		name:           payload.name
		description:    payload.description
		email:          payload.email
		public_key:     payload.public_key
		phone:          payload.phone
		address:        payload.address
		avatar_url:     payload.avatar_url
		bio:            payload.bio
		timezone:       payload.timezone
		status:         payload.status
		securitypolicy: payload.securitypolicy
		tags:           payload.tags
		comments:       payload.comments
	)!

	id := mydb.user.set(user_obj)!

	return new_response_u32(request.id, id)
}

pub fn user_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[UserDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.user.delete(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn user_list(request Request) !Response {
	mut mydb := heromodels.new()!
	users := mydb.user.list()!

	return jsonrpc.new_response(request.id, json.encode(users))
}
