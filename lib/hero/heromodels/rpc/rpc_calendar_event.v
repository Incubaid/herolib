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
	name              string
	description       string
	title             string
	start_time        string // use ourtime module to go from string to epoch
	end_time          string // use ourtime module to go from string to epoch
	registration_desks []u32 //link to registration mechanism, is where we track invitees, are not attendee unless accepted
	attendees         []heromodels.AttendeeArg
	docs              []heromodels.EventDocArg // IDs of linked files or dirs
	calendar_id       u32              // Associated calendar
	status            heromodels.EventStatus
	is_all_day        bool
	reminder_mins     []int            // Minutes before event for reminders
	color             string           // Hex color code
	timezone          string
	priority          heromodels.EventPriority
	public            bool
	locations         []heromodels.EventLocationArg
	is_template       bool //not to be shown as real event, serves as placeholder e.g. for planning
	securitypolicy    u32
	tags              []string
	messages          []db.MessageArg
}

@[params]
pub struct AttendeeArg {
pub mut:
	user_id             u32
	status_latest       heromodels.AttendanceStatus
	attendance_required bool
	admin               bool
	organizer           bool
	log                 []heromodels.AttendeeLog
	location            string
}

@[params]
pub struct EventDocArg {
pub mut:
	fs_item u32
	cat     string
	public  bool
}

@[params]
pub struct EventLocationArg {
pub mut:
	name        string
	description string
	cat         heromodels.EventLocationCat
	docs        []heromodels.EventDoc // link to docs
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
		name:              payload.name
		description:       payload.description
		title:             payload.title
		start_time:        payload.start_time
		end_time:          payload.end_time
		registration_desks: payload.registration_desks
		attendees:         payload.attendees
		docs:              payload.docs
		calendar_id:       payload.calendar_id
		status:            payload.status
		is_all_day:        payload.is_all_day
		reminder_mins:     payload.reminder_mins
		color:             payload.color
		timezone:          payload.timezone
		priority:          payload.priority
		public:            payload.public
		locations:         payload.locations
		is_template:       payload.is_template
		securitypolicy:    payload.securitypolicy
		tags:              payload.tags
		messages:          payload.messages
	)!

	calendar_event_obj = mydb.calendar_event.set(calendar_event_obj)!

	return new_response_u32(request.id, calendar_event_obj.id)
}

pub fn calendar_event_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[CalendarEventDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.calendar_event.delete(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn calendar_event_exist(request Request) !Response {
	payload := jsonrpc.decode_payload[CalendarEventGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	exists := mydb.calendar_event.exist(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

@[params]
pub struct CalendarEventListArgs {
pub mut:
	calendar_id u32
	status      heromodels.EventStatus
	public      bool
	limit       int = 100 // Default limit is 100
}

pub fn calendar_event_list(request Request) !Response {
	payload := jsonrpc.decode_payload[CalendarEventListArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	calendar_events := mydb.calendar_event.list(payload)!

	return jsonrpc.new_response(request.id, json.encode(calendar_events))
}
