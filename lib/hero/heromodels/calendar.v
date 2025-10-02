module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import freeflowuniverse.herolib.ui.console

// Calendar represents a collection of events
@[heap]
pub struct Calendar {
	db.Base
pub mut:
	events    []u32  // IDs of calendar events
	color     string // Hex color code
	timezone  string
	is_public bool
}

pub struct DBCalendar {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Calendar) type_name() string {
	return 'calendar'
}

// return example rpc call and result for each methodname
pub fn (self Calendar) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a calendar. Returns the ID of the calendar.'
		}
		'update' {
			return 'Update an existing calendar by ID. Returns the updated calendar object.'
		}
		'get' {
			return 'Retrieve a calendar by ID. Returns the calendar object.'
		}
		'delete' {
			return 'Delete a calendar by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a calendar exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all calendars. Returns an array of calendar objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self Calendar) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"calendar": {"name": "My Calendar", "description": "A personal calendar", "color": "#FF0000", "timezone": "UTC", "is_public": true, "events": []}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "My Calendar", "description": "A personal calendar", "color": "#FF0000", "timezone": "UTC", "is_public": true, "events": []}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "My Calendar", "description": "A personal calendar", "color": "#FF0000", "timezone": "UTC", "is_public": true, "events": []}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Calendar) dump(mut e encoder.Encoder) ! {
	e.add_list_u32(self.events)
	e.add_string(self.color)
	e.add_string(self.timezone)
	e.add_bool(self.is_public)
}

fn (mut self DBCalendar) load(mut o Calendar, mut e encoder.Decoder) ! {
	o.events = e.get_list_u32()!
	o.color = e.get_string()!
	o.timezone = e.get_string()!
	o.is_public = e.get_bool()!
}

@[params]
pub struct CalendarArg {
pub mut:
	id             u32 // Required for update, ignored for set
	name           string
	description    string
	color          string
	timezone       string
	is_public      bool
	events         []u32
	securitypolicy u32
	tags           []string
	messages       []db.MessageArg
}

// get new calendar, not from the DB
pub fn (mut self DBCalendar) new(args CalendarArg) !Calendar {
	mut o := Calendar{
		color:     args.color
		timezone:  args.timezone
		is_public: args.is_public
		events:    args.events
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.messages = self.db.messages_get(args.messages)!
	o.updated_at = ourtime.now().unix()

	return o
}

// update existing calendar
pub fn (mut self DBCalendar) update(args CalendarArg) !Calendar {
	// Create new object with all the updated data
	mut updated := self.new(args)!
	// Set the ID to update existing record
	updated.id = args.id
	// Use set method which will replace the existing record
	return self.set(updated)!
}

pub fn (mut self DBCalendar) set(o Calendar) !Calendar {
	// Use db set function which returns the object with assigned ID
	return self.db.set[Calendar](o)!
}

pub fn (mut self DBCalendar) delete(id u32) !bool {
	// Check if the item exists before trying to delete
	if !self.db.exists[Calendar](id)! {
		return false
	}
	self.db.delete[Calendar](id)!
	return true
}

pub fn (mut self DBCalendar) exist(id u32) !bool {
	return self.db.exists[Calendar](id)!
}

pub fn (mut self DBCalendar) get(id u32) !Calendar {
	mut o, data := self.db.get_data[Calendar](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBCalendar) list() ![]Calendar {
	return self.db.list[Calendar]()!.map(self.get(it)!)
}

pub fn calendar_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	mut converter := ResponseConverter{
		db: f.calendar.db
	}

	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.calendar.get(id)!
			// Use generic converter for consistent string timestamps and tags
			response_json := converter.convert_model_to_response(res)!
			return new_response(rpcid, response_json)
		}
		'set' {
			args := db.decode_generic[CalendarArg](params)!
			mut o := f.calendar.new(args)!
			o = f.calendar.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'update' {
			args := db.decode_generic[CalendarArg](params)!
			if args.id == 0 {
				return new_error(rpcid, code: 400, message: 'ID is required for update operation')
			}
			o := f.calendar.update(args)!
			// Return updated object with string conversion
			response_json := converter.convert_model_to_response(o)!
			return new_response(rpcid, response_json)
		}
		'delete' {
			id := db.decode_u32(params)!
			deleted := f.calendar.delete(id)!
			if deleted {
				return new_response_true(rpcid)
			} else {
				return new_error(rpcid,
					code:    404
					message: 'Calendar with ID ${id} not found'
				)
			}
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.calendar.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			res := f.calendar.list()!
			// Use generic converter for consistent string timestamps and tags
			response_json := converter.convert_list_to_response(res)!
			return new_response(rpcid, response_json)
		}
		else {
			console.print_stderr('Method not found on calendar: ${method}')
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on calendar'
			)
		}
	}
}
