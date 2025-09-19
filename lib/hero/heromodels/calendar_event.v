module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_ok, new_response_true, new_response_int }
import freeflowuniverse.herolib.hero.user { UserRef }
import json

// CalendarEvent represents a single event in a calendar
@[heap]
pub struct CalendarEvent {
	db.Base
pub mut:
	title         string
	start_time    i64 // Unix timestamp
	end_time      i64 // Unix timestamp
	location      string
	attendees     []u32 // IDs of user groups
	docs      []u32 // IDs of linked files or dirs
	registration_desk_id u32   // ID of the registration desk
	calendar_id   u32   // Associated calendar
	status        EventStatus
	is_all_day    bool
	reminder_mins []int            // Minutes before event for reminders
	color         string           // Hex color code
	timezone      string
}

pub struct Attendee {
pub mut:
	user_id u32
	status  AttendanceStatus
	role    AttendeeRole
}

pub enum AttendanceStatus {
	no_response
	accepted
	declined
	tentative
}

pub enum AttendeeRole {
	required
	optional
	organizer
}

pub enum EventStatus {
	draft
	published
	cancelled
	completed
}

pub struct DBCalendarEvent {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self CalendarEvent) type_name() string {
	return 'calendar_event'
}

// return example rpc call and result for each methodname
pub fn (self CalendarEvent) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a calendar event. Returns the ID of the event.'
		}
		'get' {
			return 'Retrieve a calendar event by ID. Returns the event object.'
		}
		'delete' {
			return 'Delete a calendar event by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a calendar event exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all calendar events. Returns an array of event objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname, so example for call and the result
pub fn (self CalendarEvent) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"calendar_event": {"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "location": "Office", "attendees": [], "docs": [], "calendar_id": 1, "status": "published", "is_all_day": false, "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "location": "Office", "attendees": [], "docs": [], "calendar_id": 1, "status": "published", "is_all_day": false, "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "location": "Office", "attendees": [], "docs": [], "calendar_id": 1, "status": "published", "is_all_day": false, "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self CalendarEvent) dump(mut e encoder.Encoder) ! {
	e.add_string(self.title)
	e.add_i64(self.start_time)
	e.add_i64(self.end_time)
	e.add_string(self.location)
	e.add_list_u32(self.attendees)
	e.add_list_u32(self.docs)
	e.add_u32(self.calendar_id)
	e.add_u8(u8(self.status))
	e.add_bool(self.is_all_day)
	e.add_list_int(self.reminder_mins)
	e.add_string(self.color)
	e.add_string(self.timezone)
}

fn (mut self DBCalendarEvent) load(mut o CalendarEvent, mut e encoder.Decoder) ! {
	o.title = e.get_string()!
	o.start_time = e.get_i64()!
	o.end_time = e.get_i64()!
	o.location = e.get_string()!
	o.attendees = e.get_list_u32()!
	o.docs = e.get_list_u32()!
	o.calendar_id = e.get_u32()!
	o.status = unsafe { EventStatus(e.get_u8()!) }
	o.is_all_day = e.get_bool()!
	o.reminder_mins = e.get_list_int()!
	o.color = e.get_string()!
	o.timezone = e.get_string()!
}

@[params]
pub struct CalendarEventArg {
pub mut:
	name           string
	description    string
	title          string
	start_time     string // use ourtime module to go from string to epoch
	end_time       string // use ourtime module to go from string to epoch
	location       string
	attendees      []u32 // IDs of user groups
	docs       []u32 // IDs of linked files or dirs
	calendar_id    u32   // Associated calendar
	status         EventStatus
	is_all_day     bool
	reminder_mins  []int  // Minutes before event for reminders
	color          string // Hex color code
	timezone       string
	securitypolicy u32
	tags           []string
	messages       []db.MessageArg
}

// get new calendar event, not from the DB
pub fn (mut self DBCalendarEvent) new(args CalendarEventArg) !CalendarEvent {
	mut o := CalendarEvent{
		title:         args.title
		location:      args.location
		attendees:     args.attendees
		docs:      args.docs
		calendar_id:   args.calendar_id
		status:        args.status
		is_all_day:    args.is_all_day
		reminder_mins: args.reminder_mins
		color:         args.color
		timezone:      args.timezone
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.messages = self.db.messages_get(args.messages)!
	o.updated_at = ourtime.now().unix()

	// Convert string times to Unix timestamps
	mut start_time_obj := ourtime.new(args.start_time)!
	o.start_time = start_time_obj.unix()

	mut end_time_obj := ourtime.new(args.end_time)!
	o.end_time = end_time_obj.unix()

	return o
}

pub fn (mut self DBCalendarEvent) set(o CalendarEvent) !CalendarEvent {
	// Use db set function which returns the object with assigned ID
	return self.db.set[CalendarEvent](o)!
}

pub fn (mut self DBCalendarEvent) delete(id u32) ! {
	self.db.delete[CalendarEvent](id)!
}

pub fn (mut self DBCalendarEvent) exist(id u32) !bool {
	return self.db.exists[CalendarEvent](id)!
}

pub fn (mut self DBCalendarEvent) get(id u32) !CalendarEvent {
	mut o, data := self.db.get_data[CalendarEvent](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBCalendarEvent) list() ![]CalendarEvent {
	return self.db.list[CalendarEvent]()!.map(self.get(it)!)
}


pub fn calendar_event_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.calendar_event.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut o := db.decode_generic[CalendarEvent](params)!
			o = f.calendar_event.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			f.calendar_event.delete(id)!
			return new_response_ok(rpcid)
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.calendar_event.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			req := jsonrpc.new_request(method, '')
			res := f.calendar_event.list()!
			return new_response(req.id, json.encode(res))
		}
		else {
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on calendar_event'
			)
		}
	}
}
