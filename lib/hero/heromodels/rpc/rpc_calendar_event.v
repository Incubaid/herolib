module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.hero.db
// CalendarEvent-specific argument structures

@[params]
pub struct CalendarEventGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct CalendarEventSetArgs {
pub mut:
	name           string
	description    string
	title          string
	start_time     string // use ourtime module to go from string to epoch
	end_time       string // use ourtime module to go from string to epoch
	location       string
	attendees      []u32 // IDs of user groups
	fs_items       []u32 // IDs of linked files or dirs
	calendar_id    u32   // Associated calendar
	status         heromodels.EventStatus
	is_all_day     bool
	is_recurring   bool
	recurrence     []heromodels.RecurrenceRule
	reminder_mins  []int  // Minutes before event for reminders
	color          string // Hex color code
	timezone       string
	securitypolicy u32
	tags           []string
	comments       []db.CommentArg
}

@[params]
pub struct CalendarEventDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn calendar_event_get(request Request) !Response {
	payload := jsonrpc.decode_payload[CalendarEventGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	calendar_event := mydb.calendar_event.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(calendar_event))
}

pub fn calendar_event_set(request Request) !Response {
	payload := jsonrpc.decode_payload[CalendarEventSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut calendar_event_obj := mydb.calendar_event.new(
		name:           payload.name
		description:    payload.description
		title:          payload.title
		start_time:     payload.start_time
		end_time:       payload.end_time
		location:       payload.location
		attendees:      payload.attendees
		fs_items:       payload.fs_items
		calendar_id:    payload.calendar_id
		status:         payload.status
		is_all_day:     payload.is_all_day
		is_recurring:   payload.is_recurring
		recurrence:     payload.recurrence
		reminder_mins:  payload.reminder_mins
		color:          payload.color
		timezone:       payload.timezone
		securitypolicy: payload.securitypolicy
		tags:           payload.tags
		comments:       payload.comments
	)!

	id := mydb.calendar_event.set(calendar_event_obj)!

	return new_response_u32(request.id, id)
}

pub fn calendar_event_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[CalendarEventDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.calendar_event.delete(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn calendar_event_list(request Request) !Response {
	mut mydb := heromodels.new()!
	calendar_events := mydb.calendar_event.list()!

	return jsonrpc.new_response(request.id, json.encode(calendar_events))
}
