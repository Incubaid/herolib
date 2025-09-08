module heromodels

import crypto.blake3
import json
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.core.redisclient

// CalendarEvent represents a single event in a calendar
@[heap]
pub struct CalendarEvent {
	Base
pub mut:
	title         string
	start_time    i64 // Unix timestamp
	end_time      i64 // Unix timestamp
	location      string
	attendees     []u32 // IDs of user groups
	fs_items      []u32 // IDs of linked files or dirs
	calendar_id   u32   // Associated calendar
	status        EventStatus
	is_all_day    bool
	is_recurring  bool
	recurrence    []RecurrenceRule // normally empty
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

pub struct RecurrenceRule {
pub mut:
	frequency   RecurrenceFreq
	interval    int   // Every N frequencies
	until       i64   // End date (Unix timestamp)
	count       int   // Number of occurrences
	by_weekday  []int // Days of week (0=Sunday)
	by_monthday []int // Days of month
}

pub enum RecurrenceFreq {
	none
	daily
	weekly
	monthly
	yearly
}

@[params]
pub struct CalendarEventArgs {
	BaseArgs
pub mut:
	title         string
	start_time    string // use ourtime module to go from string to epoch
	end_time      string // use ourtime module to go from string to epoch
	location      string
	attendees     []u32 // IDs of user groups
	fs_items      []u32 // IDs of linked files or dirs
	calendar_id   u32   // Associated calendar
	status        EventStatus
	is_all_day    bool
	is_recurring  bool
	recurrence    []RecurrenceRule
	reminder_mins []int  // Minutes before event for reminders
	color         string // Hex color code
	timezone      string
}

pub fn calendar_event_new(args CalendarEventArgs) !CalendarEvent {
	// Convert tags to u32 ID
	tags_id := tags2id(args.tags)!

	return CalendarEvent{
		// Base fields
		id:             args.id or { 0 }
		name:           args.name
		description:    args.description
		created_at:     ourtime.now().unix()
		updated_at:     ourtime.now().unix()
		securitypolicy: args.securitypolicy or { 0 }
		tags:           tags_id
		comments:       comments2ids(args.comments)!

		// CalendarEvent specific fields
		title:         args.title
		start_time:    ourtime.new(args.start_time)!.unix()
		end_time:      ourtime.new(args.end_time)!.unix()
		location:      args.location
		attendees:     args.attendees
		fs_items:      args.fs_items
		calendar_id:   args.calendar_id
		status:        args.status
		is_all_day:    args.is_all_day
		is_recurring:  args.is_recurring
		recurrence:    args.recurrence
		reminder_mins: args.reminder_mins
		color:         args.color
		timezone:      args.timezone
	}
}

pub fn (mut e CalendarEvent) dump() ![]u8 {
	// Create a new encoder
	mut enc := encoder.new()

	// Add version byte
	enc.add_u8(1)

	// Encode Base fields
	enc.add_u32(e.id)
	enc.add_string(e.name)
	enc.add_string(e.description)
	enc.add_i64(e.created_at)
	enc.add_i64(e.updated_at)
	enc.add_u32(e.securitypolicy)
	enc.add_u32(e.tags)
	enc.add_list_u32(e.comments)

	// Encode CalendarEvent specific fields
	enc.add_string(e.title)
	enc.add_string(e.description)
	enc.add_i64(e.start_time)
	enc.add_i64(e.end_time)
	enc.add_string(e.location)
	enc.add_list_u32(e.attendees)
	enc.add_list_u32(e.fs_items)
	enc.add_u32(e.calendar_id)
	enc.add_u8(u8(e.status))
	enc.add_bool(e.is_all_day)
	enc.add_bool(e.is_recurring)

	// Encode recurrence array
	enc.add_u16(u16(e.recurrence.len))
	for rule in e.recurrence {
		enc.add_u8(u8(rule.frequency))
		enc.add_int(rule.interval)
		enc.add_i64(rule.until)
		enc.add_int(rule.count)
		enc.add_list_int(rule.by_weekday)
		enc.add_list_int(rule.by_monthday)
	}

	enc.add_list_int(e.reminder_mins)
	enc.add_string(e.color)
	enc.add_string(e.timezone)

	return enc.data
}

pub fn (ce CalendarEvent) load(data []u8) !CalendarEvent {
	// Create a new decoder
	mut dec := encoder.decoder_new(data)

	// Read version byte
	version := dec.get_u8()!
	if version != 1 {
		return error('wrong version in calendar event load')
	}

	// Decode Base fields
	id := dec.get_u32()!
	name := dec.get_string()!
	description := dec.get_string()!
	created_at := dec.get_i64()!
	updated_at := dec.get_i64()!
	securitypolicy := dec.get_u32()!
	tags := dec.get_u32()!
	comments := dec.get_list_u32()!

	// Decode CalendarEvent specific fields
	title := dec.get_string()!
	description2 := dec.get_string()! // Second description field
	start_time := dec.get_i64()!
	end_time := dec.get_i64()!
	location := dec.get_string()!
	attendees := dec.get_list_u32()!
	fs_items := dec.get_list_u32()!
	calendar_id := dec.get_u32()!
	status := unsafe { EventStatus(dec.get_u8()!) }
	is_all_day := dec.get_bool()!
	is_recurring := dec.get_bool()!

	// Decode recurrence array
	recurrence_len := dec.get_u16()!
	mut recurrence := []RecurrenceRule{}
	for _ in 0 .. recurrence_len {
		frequency := unsafe { RecurrenceFreq(dec.get_u8()!) }
		interval := dec.get_int()!
		until := dec.get_i64()!
		count := dec.get_int()!
		by_weekday := dec.get_list_int()!
		by_monthday := dec.get_list_int()!

		recurrence << RecurrenceRule{
			frequency:   frequency
			interval:    interval
			until:       until
			count:       count
			by_weekday:  by_weekday
			by_monthday: by_monthday
		}
	}

	reminder_mins := dec.get_list_int()!
	color := dec.get_string()!
	timezone := dec.get_string()!

	return CalendarEvent{
		// Base fields
		id:             id
		name:           name
		description:    description
		created_at:     created_at
		updated_at:     updated_at
		securitypolicy: securitypolicy
		tags:           tags
		comments:       comments

		// CalendarEvent specific fields
		title:         title
		start_time:    start_time
		end_time:      end_time
		location:      location
		attendees:     attendees
		fs_items:      fs_items
		calendar_id:   calendar_id
		status:        status
		is_all_day:    is_all_day
		is_recurring:  is_recurring
		recurrence:    recurrence
		reminder_mins: reminder_mins
		color:         color
		timezone:      timezone
	}
}
