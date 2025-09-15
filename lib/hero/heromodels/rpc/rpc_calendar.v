module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels

// Calendar-specific argument structures
@[params]
pub struct CalendarGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct CalendarSetArgs {
pub mut:
	name        string @[required]
	description string
	color       string
	timezone    string
	is_public   bool
	events      []u32
}

@[params]
pub struct CalendarDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn calendar_get(request Request) !Response {
	payload := jsonrpc.decode_payload[CalendarGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	calendar := mydb.calendar.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(calendar))
}

pub fn calendar_set(request Request) !Response {
	payload := jsonrpc.decode_payload[CalendarSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut calendar_obj := mydb.calendar.new(
		name:        payload.name
		description: payload.description
		color:       payload.color
		timezone:    payload.timezone
		is_public:   payload.is_public
		events:      payload.events
	)!

	mydb.calendar.set(mut calendar_obj)!

	return new_response_u32(request.id, calendar_obj.id)
}

pub fn calendar_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[CalendarDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.calendar.delete(payload.id)!

	// returns
	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn calendar_list(request Request) !Response {
	mut mydb := heromodels.new()!
	calendars := mydb.calendar.list()!

	return jsonrpc.new_response(request.id, json.encode(calendars))
}
