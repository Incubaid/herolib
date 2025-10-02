module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import freeflowuniverse.herolib.hero.db

// CalendarEvent represents a single event in a calendar
@[heap]
pub struct CalendarEvent {
	db.Base
pub mut:
	title              string
	start_time         i64   // Unix timestamp
	end_time           i64   // Unix timestamp
	registration_desks []u32 // link to registration mechanism, is where we track invitees, are not attendee unless accepted
	attendees          []Attendee
	docs               []EventDoc // link to docs
	calendar_id        u32        // Associated calendar
	status             EventStatus
	is_all_day         bool
	reminder_mins      []int  // Minutes before event for reminders
	color              string // Hex color code
	timezone           string
	priority           EventPriority
	public             bool
	locations          []EventLocation
	is_template        bool // not to be shown as real event, serves as placeholder e.g. for planning
}

pub struct Attendee {
pub mut:
	user_id             u32
	status_latest       AttendanceStatus
	attendance_required bool
	admin               bool // if set can manage the main elements of the event = description, can accept invitee...
	organizer           bool // if set means others can ask for support, doesn't mean is admin
	log                 []AttendeeLog
	location            string // optional if user wants to select a location
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

pub struct EventDoc {
pub mut:
	fs_item u32
	cat     string // can be freely chosen, will always be made lowercase e.g. agenda
	public  bool   // everyone can see the file, otherwise only the organizers, attendees
}

pub struct EventLocation {
pub mut:
	name        string
	description string
	cat         EventLocationCat
	docs        []EventDoc
}

pub enum EventLocationCat {
	online
	physical
	hybrid
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
		'update' {
			return 'Update an existing calendar event. Returns the updated event object.'
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
			return '{"calendar_event": {"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "attendees": [], "docs": [], "calendar_id": 1, "status": "published", "is_all_day": false, "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC", "locations": []}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "attendees": [], "docs": [], "calendar_id": 1, "status": "published", "is_all_day": false, "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC", "locations": []}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "attendees": [], "docs": [], "calendar_id": 1, "status": "published", "is_all_day": false, "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC", "locations": []}]'
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

	// Encode registration_desks array
	e.add_list_u32(self.registration_desks)

	// Encode attendees array
	e.add_u16(u16(self.attendees.len))
	for attendee in self.attendees {
		e.add_u32(attendee.user_id)
		e.add_u8(u8(attendee.status_latest))
		e.add_bool(attendee.attendance_required)
		e.add_bool(attendee.admin)
		e.add_bool(attendee.organizer)
		e.add_string(attendee.location) // Added missing location field

		// Encode AttendeeLog array
		e.add_u16(u16(attendee.log.len))
		for log_entry in attendee.log {
			e.add_u64(log_entry.timestamp)
			e.add_u8(u8(log_entry.status))
			e.add_string(log_entry.remark)
		}
	}

	// Encode docs array
	e.add_u16(u16(self.docs.len))
	for fs_item in self.docs {
		e.add_u32(fs_item.fs_item)
		e.add_string(fs_item.cat)
		e.add_bool(fs_item.public)
	}

	e.add_u32(self.calendar_id)
	e.add_u8(u8(self.status))
	e.add_bool(self.is_all_day)
	e.add_bool(self.public)
	e.add_u8(u8(self.priority))

	// Encode locations array
	e.add_u16(u16(self.locations.len))
	for location in self.locations {
		e.add_string(location.name)
		e.add_string(location.description)
		e.add_u8(u8(location.cat))

		// Encode location docs array
		e.add_u16(u16(location.docs.len))
		for fs_item in location.docs {
			e.add_u32(fs_item.fs_item)
			e.add_string(fs_item.cat)
			e.add_bool(fs_item.public)
		}
	}

	e.add_list_int(self.reminder_mins)
	e.add_string(self.color)
	e.add_string(self.timezone)
	e.add_bool(self.is_template) // Added missing is_template field
}

pub fn (mut self DBCalendarEvent) load(mut o CalendarEvent, mut e encoder.Decoder) ! {
	o.title = e.get_string()!
	o.start_time = e.get_i64()!
	o.end_time = e.get_i64()!

	// Decode registration_desks array
	o.registration_desks = e.get_list_u32()!

	// Decode attendees array
	attendees_len := e.get_u16()!
	mut attendees := []Attendee{}
	for _ in 0 .. attendees_len {
		user_id := e.get_u32()!
		status_latest := unsafe { AttendanceStatus(e.get_u8()!) }
		attendance_required := e.get_bool()!
		admin := e.get_bool()!
		organizer := e.get_bool()!
		location := e.get_string()! // Added missing location field

		// Decode AttendeeLog array
		log_len := e.get_u16()!
		mut log_entries := []AttendeeLog{}
		for _ in 0 .. log_len {
			timestamp := e.get_u64()!
			status := unsafe { AttendanceStatus(e.get_u8()!) }
			remark := e.get_string()!

			log_entries << AttendeeLog{
				timestamp: timestamp
				status:    status
				remark:    remark
			}
		}

		attendees << Attendee{
			user_id:             user_id
			status_latest:       status_latest
			attendance_required: attendance_required
			admin:               admin
			organizer:           organizer
			log:                 log_entries
			location:            location // Added missing location field
		}
	}
	o.attendees = attendees

	// Decode docs array
	docs_len := e.get_u16()!
	mut docs := []EventDoc{}
	for _ in 0 .. docs_len {
		fs_item := e.get_u32()!
		cat := e.get_string()!
		public := e.get_bool()!

		docs << EventDoc{
			fs_item: fs_item
			cat:     cat
			public:  public
		}
	}
	o.docs = docs

	o.calendar_id = e.get_u32()!
	o.status = unsafe { EventStatus(e.get_u8()!) } // TODO: is there no better way?
	o.is_all_day = e.get_bool()!
	o.public = e.get_bool()! // Added missing public field
	o.priority = unsafe { EventPriority(e.get_u8()!) } // Added missing priority field

	// Decode locations array
	locations_len := e.get_u16()!
	mut locations := []EventLocation{}
	for _ in 0 .. locations_len {
		name := e.get_string()!
		description := e.get_string()!
		cat := unsafe { EventLocationCat(e.get_u8()!) }

		// Decode location docs array
		location_docs_len := e.get_u16()!
		mut location_docs := []EventDoc{}
		for _ in 0 .. location_docs_len {
			fs_item := e.get_u32()!
			doc_cat := e.get_string()!
			public := e.get_bool()!

			location_docs << EventDoc{
				fs_item: fs_item
				cat:     doc_cat
				public:  public
			}
		}

		locations << EventLocation{
			name:        name
			description: description
			cat:         cat
			docs:        location_docs
		}
	}
	o.locations = locations

	o.reminder_mins = e.get_list_int()!
	o.color = e.get_string()!
	o.timezone = e.get_string()!
	o.is_template = e.get_bool()! // Added missing is_template field
}

@[params]
pub struct CalendarEventArg {
pub mut:
	id                 u32 // Required for update, ignored for set
	name               string
	description        string
	title              string
	start_time         string // use ourtime module to go from string to epoch
	end_time           string // use ourtime module to go from string to epoch
	registration_desks []u32  // link to registration mechanism
	attendees          []u32  // IDs of user groups
	docs               []u32  // IDs of linked files or dirs
	calendar_id        u32    // Associated calendar
	status             EventStatus
	is_all_day         bool
	reminder_mins      []int  // Minutes before event for reminders
	color              string // Hex color code
	timezone           string
	priority           EventPriority
	public             bool
	locations          []string // Simplified location names for RPC
	is_template        bool
	securitypolicy     u32
	tags               []string
	messages           []db.MessageArg
}

// get new calendar event, not from the DB
pub fn (mut self DBCalendarEvent) new(args CalendarEventArg) !CalendarEvent {
	// Convert docs from []u32 to []EventDoc
	mut fs_attachments := []EventDoc{}
	for fs_item_id in args.docs {
		fs_attachments << EventDoc{
			fs_item: fs_item_id
			cat:     ''
			public:  false
		}
	}

	// Convert locations from []string to []EventLocation
	mut event_locations := []EventLocation{}
	for location_name in args.locations {
		event_locations << EventLocation{
			name:        location_name
			description: ''
			cat:         .physical // Default to physical location
			docs:        []EventDoc{}
		}
	}

	mut o := CalendarEvent{
		title:              args.title
		registration_desks: args.registration_desks
		attendees:          []Attendee{} // TODO: Convert from u32 IDs if needed
		docs:               fs_attachments
		calendar_id:        args.calendar_id
		status:             args.status
		is_all_day:         args.is_all_day
		reminder_mins:      args.reminder_mins
		color:              args.color
		timezone:           args.timezone
		priority:           args.priority
		public:             args.public
		locations:          event_locations
		is_template:        args.is_template
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

// Convert CalendarEvent to CalendarEventArg (for API responses or conversions)
pub fn (self CalendarEvent) to_args() CalendarEventArg {
	// Convert timestamps to string format
	start_time_str := ourtime.new_from_epoch(u64(self.start_time)).str()
	end_time_str := ourtime.new_from_epoch(u64(self.end_time)).str()

	// Convert attendees to simple u32 array
	mut attendee_ids := []u32{}
	for attendee in self.attendees {
		attendee_ids << attendee.user_id
	}

	// Convert docs to simple u32 array
	mut doc_ids := []u32{}
	for doc in self.docs {
		doc_ids << doc.fs_item
	}

	// Convert locations to simple string array
	mut location_names := []string{}
	for location in self.locations {
		location_names << location.name
	}

	return CalendarEventArg{
		name:               self.name
		description:        self.description
		title:              self.title
		start_time:         start_time_str
		end_time:           end_time_str
		registration_desks: self.registration_desks
		attendees:          attendee_ids
		docs:               doc_ids
		calendar_id:        self.calendar_id
		status:             self.status
		is_all_day:         self.is_all_day
		reminder_mins:      self.reminder_mins
		color:              self.color
		timezone:           self.timezone
		priority:           self.priority
		public:             self.public
		locations:          location_names
		is_template:        self.is_template
		securitypolicy:     self.securitypolicy
		tags:               []string{} // Note: requires DB access to convert from hash
		messages:           []db.MessageArg{} // Note: requires DB access to convert
	}
}

// Convert CalendarEvent to CalendarEventArg with database access for tags and messages
pub fn (mut self DBCalendarEvent) to_args_with_db(event CalendarEvent) !CalendarEventArg {
	mut args := event.to_args()
	// Convert hashed tags back to strings
	args.tags = self.db.tags_to_strings(event.tags)!
	// TODO: Convert messages if needed in the future
	return args
}

// Create CalendarEvent from CalendarEventArg (alias for new method for consistency)
pub fn (mut self DBCalendarEvent) from_args(args CalendarEventArg) !CalendarEvent {
	return self.new(args)!
}

pub fn (mut self DBCalendarEvent) set(o CalendarEvent) !CalendarEvent {
	// Use db set function which returns the object with assigned ID
	return self.db.set[CalendarEvent](o)!
}

// update existing calendar event
pub fn (mut self DBCalendarEvent) update(args CalendarEventArg) !CalendarEvent {
	// Create new object with all the updated data
	mut updated := self.new(args)!
	// Set the ID to update existing record
	updated.id = args.id
	// Use set method which will replace the existing record
	return self.set(updated)!
}

pub fn (mut self DBCalendarEvent) delete(id u32) !bool {
	// Check if the item exists before trying to delete
	if !self.db.exists[CalendarEvent](id)! {
		return false
	}
	self.db.delete[CalendarEvent](id)!
	return true
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

@[params]
pub struct CalendarEventListArg {
pub mut:
	calendar_id u32
	status      EventStatus
	public      bool
	limit       int = 100 // Default limit is 100
}

pub fn (mut self DBCalendarEvent) list(args CalendarEventListArg) ![]CalendarEvent {
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
	mut limit := args.limit
	if limit > 100 {
		limit = 100
	}
	if filtered_events.len > limit {
		return filtered_events[..limit]
	}

	return filtered_events
}

// CalendarEventResponse represents the RPC response format with string tags and timestamps
pub struct CalendarEventResponse {
pub mut:
	id                 u32
	name               string
	description        string
	created_at         string // String timestamp instead of i64
	updated_at         string // String timestamp instead of i64
	securitypolicy     u32
	tags               []string // String tags instead of hashed ID
	messages           []u32
	title              string
	start_time         string // String timestamp instead of i64
	end_time           string // String timestamp instead of i64
	registration_desks []u32
	attendees          []Attendee
	docs               []EventDoc
	calendar_id        u32
	status             EventStatus
	is_all_day         bool
	reminder_mins      []int
	color              string
	timezone           string
	priority           EventPriority
	public             bool
	locations          []EventLocation
	is_template        bool
}

// Convert CalendarEvent to CalendarEventResponse with string tags and timestamps
pub fn (mut self DBCalendarEvent) to_response(event CalendarEvent) !CalendarEventResponse {
	tags_strings := self.db.tags_to_strings(event.tags)!

	// Convert all timestamps to string format
	created_at_str := ourtime.new_from_epoch(u64(event.created_at)).str()
	updated_at_str := ourtime.new_from_epoch(u64(event.updated_at)).str()
	start_time_str := ourtime.new_from_epoch(u64(event.start_time)).str()
	end_time_str := ourtime.new_from_epoch(u64(event.end_time)).str()

	return CalendarEventResponse{
		id:                 event.id
		name:               event.name
		description:        event.description
		created_at:         created_at_str
		updated_at:         updated_at_str
		securitypolicy:     event.securitypolicy
		tags:               tags_strings
		messages:           event.messages
		title:              event.title
		start_time:         start_time_str
		end_time:           end_time_str
		registration_desks: event.registration_desks
		attendees:          event.attendees
		docs:               event.docs
		calendar_id:        event.calendar_id
		status:             event.status
		is_all_day:         event.is_all_day
		reminder_mins:      event.reminder_mins
		color:              event.color
		timezone:           event.timezone
		priority:           event.priority
		public:             event.public
		locations:          event.locations
		is_template:        event.is_template
	}
}

pub fn calendar_event_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	mut converter := ResponseConverter{
		db: f.calendar_event.db
	}

	match method {
		'get' {
			id := db.decode_u32(params)!
			event := f.calendar_event.get(id)!
			// Use generic converter for consistent string timestamps and tags
			response_json := converter.convert_model_to_response(event)!
			return new_response(rpcid, response_json)
		}
		'set' {
			args := db.decode_generic[CalendarEventArg](params)!
			mut o := f.calendar_event.new(args)!
			o = f.calendar_event.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'update' {
			args := db.decode_generic[CalendarEventArg](params)!
			if args.id == 0 {
				return new_error(rpcid, code: 400, message: 'ID is required for update operation')
			}
			o := f.calendar_event.update(args)!
			// Return updated object with string conversion
			response_json := converter.convert_model_to_response(o)!
			return new_response(rpcid, response_json)
		}
		'delete' {
			id := db.decode_u32(params)!
			deleted := f.calendar_event.delete(id)!
			if deleted {
				return new_response_true(rpcid)
			} else {
				return new_error(rpcid,
					code:    404
					message: 'Calendar event with ID ${id} not found'
				)
			}
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
			args := db.decode_generic[CalendarEventListArg](params)!
			events := f.calendar_event.list(args)!
			// Use generic converter for consistent string timestamps and tags
			response_json := converter.convert_list_to_response(events)!
			return new_response(rpcid, response_json)
		}
		else {
			println('Method not found on calendar_event: ${method}')
			$dbg;
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on calendar_event'
			)
		}
	}
}
