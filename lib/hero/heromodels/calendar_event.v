module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// CalendarEvent represents a single event in a calendar
@[heap]
pub struct CalendarEvent {
	db.Base
pub mut:
	title         string
	start_time    i64 // Unix timestamp
	end_time      i64 // Unix timestamp
	location      string
	attendees     []Attendee
	fs_items      []u32 // IDs of linked files or dirs
	calendar_id   u32   // Associated calendar
	status        EventStatus
	is_all_day    bool
	is_recurring  bool
	recurrence    []RecurrenceRule // normally empty
	reminder_mins []int            // Minutes before event for reminders
	color         string           // Hex color code
	timezone      string
	priority      EventPriority
	public        bool
}

pub struct Attendee {
pub mut:
	user_id             u32
	status_latest       AttendanceStatus
	attendance_required bool
	admin               bool // if set can manage the main elements of the event = description, ...
	organizer           bool // if set means others can ask for support, doesn't mean is admin
	log                 AttendeeLog
}

pub enum EventPriority {
	low
	normal
	urgent
}

pub enum EventStatus {
	draft
	published
	cancelled
	completed
}

pub struct AttendeeLog {
pub mut:
	timestamp u64
	status    AttendanceStatus
	remark    string
}

pub enum AttendanceStatus {
	invited
	accepted
	declined
	tentative
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
pub struct CalendarEventListArg {
pub mut:
	calendar_id u32
	status      EventStatus
	public      bool
	limit       int = 100 // Default limit is 100
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
			return '{"calendar_event": {"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "location": "Office", "attendees": [], "fs_items": [], "calendar_id": 1, "status": "published", "is_all_day": false, "is_recurring": false, "recurrence": [], "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "location": "Office", "attendees": [], "fs_items": [], "calendar_id": 1, "status": "published", "is_all_day": false, "is_recurring": false, "recurrence": [], "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "location": "Office", "attendees": [], "fs_items": [], "calendar_id": 1, "status": "published", "is_all_day": false, "is_recurring": false, "recurrence": [], "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

fn (self CalendarEvent) dump(mut e encoder.Encoder) ! {
	e.add_string(self.title)
	e.add_i64(self.start_time)
	e.add_i64(self.end_time)
	e.add_string(self.location)
	e.add_list_u32(self.attendees)
	e.add_list_u32(self.fs_items)
	e.add_u32(self.calendar_id)
	e.add_u8(u8(self.status))
	e.add_bool(self.is_all_day)
	e.add_bool(self.is_recurring)

	// Encode recurrence array
	e.add_u16(u16(self.recurrence.len))
	for rule in self.recurrence {
		e.add_u8(u8(rule.frequency))
		e.add_int(rule.interval)
		e.add_i64(rule.until)
		e.add_int(rule.count)
		e.add_list_int(rule.by_weekday)
		e.add_list_int(rule.by_monthday)
	}

	e.add_list_int(self.reminder_mins)
	e.add_string(self.color)
	e.add_string(self.timezone)
}

fn (mut self DBCalendarEvent) load(mut o CalendarEvent, mut e encoder.Decoder) ! {
	o.title = e.get_string()!
	o.start_time = e.get_i64()!
	o.end_time = e.get_i64()!
	o.location = e.get_string()!
	// o.attendees = e.get_list_u32()!  // This line is incorrect, attendees is []Attendee not []u32
	o.fs_items = e.get_list_u32()!
	o.calendar_id = e.get_u32()!
	o.status = unsafe { EventStatus(e.get_u8()!) } // TODO: is there no better way?
	o.is_all_day = e.get_bool()!
	o.is_recurring = e.get_bool()!

	// Decode recurrence array
	recurrence_len := e.get_u16()!
	mut recurrence := []RecurrenceRule{}
	for _ in 0 .. recurrence_len {
		frequency := unsafe { RecurrenceFreq(e.get_u8()!) }
		interval := e.get_int()!
		until := e.get_i64()!
		count := e.get_int()!
		by_weekday := e.get_list_int()!
		by_monthday := e.get_list_int()!

		recurrence << RecurrenceRule{
			frequency:   frequency
			interval:    interval
			until:       until
			count:       count
			by_weekday:  by_weekday
			by_monthday: by_monthday
		}
	}
	o.recurrence = recurrence

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
	fs_items       []u32 // IDs of linked files or dirs
	calendar_id    u32   // Associated calendar
	status         EventStatus
	is_all_day     bool
	is_recurring   bool
	recurrence     []RecurrenceRule
	reminder_mins  []int  // Minutes before event for reminders
	color          string // Hex color code
	timezone       string
	securitypolicy u32
	tags           []string
	comments       []db.CommentArg
}

// get new calendar event, not from the DB
pub fn (mut self DBCalendarEvent) new(args CalendarEventArg) !CalendarEvent {
	mut o := CalendarEvent{
		title:         args.title
		location:      args.location
		attendees:     []Attendee{}
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

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
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

pub fn (mut self DBCalendarEvent) list(args CalendarEventListArg) ![]CalendarEvent {
	// Require at least one parameter to be provided
	if args.calendar_id == 0 && args.status == .draft && !args.public {
		return error('At least one filter parameter must be provided')
	}

	// Get all calendar events from the database
	all_events := self.db.list[CalendarEvent]()!.map(self.get(it)!)

	// Apply filters
	mut filtered_events := []CalendarEvent{}
	for event in all_events {
		// Filter by calendar_id if provided
		if args.calendar_id != 0 && event.calendar_id != args.calendar_id {
			continue
		}

		// Filter by status if provided (status is not draft)
		if args.status != .draft && event.status != args.status {
			continue
		}

		// Filter by public if provided (public is true)
		if args.public && !event.public {
			continue
		}

		filtered_events << event
	}

	// Limit results to 100 or the specified limit
	limit := args.limit
	if limit > 100 {
		limit = 100
	}
	if filtered_events.len > limit {
		return filtered_events[..limit]
	}

	return filtered_events
}
