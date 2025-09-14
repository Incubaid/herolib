module openrpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc
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

pub fn calendar_get(request jsonrpc.Request) !jsonrpc.Response {
	payload := jsonrpc.decode_payload[CalendarGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	calendar := mydb.calendar.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(calendar))
}

pub fn calendar_set(request jsonrpc.Request) !jsonrpc.Response {
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

	id := mydb.calendar.set(calendar_obj)!

	return jsonrpc.new_response(request.id, json.encode({
		'id': id
	}))
}

pub fn calendar_delete(request jsonrpc.Request) !jsonrpc.Response {
	payload := jsonrpc.decode_payload[CalendarDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.calendar.delete(payload.id)!

	// returns
	return jsonrpc.new_response(request.id, 'true')
}

pub fn calendar_list(request jsonrpc.Request) !jsonrpc.Response {
	mut mydb := heromodels.new()!
	calendars := mydb.calendar.list()!

	return jsonrpc.new_response(request.id, json.encode(calendars))
}
