module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

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
	name        string
	description string
	color       string
	timezone    string
	is_public   bool
	events      []u32
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
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBCalendar) set(o Calendar) !Calendar {
	// Use db set function which returns the object with assigned ID
	return self.db.set[Calendar](o)!
}

pub fn (mut self DBCalendar) delete(id u32) ! {
	self.db.delete[Calendar](id)!
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
	r:= self.db.list[Calendar]()!.map(self.get(it)!)
	println(r)
	return r
}
