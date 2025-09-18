module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Planning represents a collection of events
@[heap]
pub struct Planning {
	db.Base
pub mut:
	color     string // Hex color code
	timezone  string
	is_public bool
	calendar_id u32 //link to calendarid which is relevant for this planning, the calendar has 

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


pub struct DBPlanning {
pub mut:
	db &db.DB @[skip; str: skip]
}

@[params]
pub struct PlanningListArg {
pub mut:
	is_public bool
	limit     int = 100 // Default limit is 100
}

pub fn (self Planning) type_name() string {
	return 'calendar'
}

// return example rpc call and result for each methodname
pub fn (self Planning) description(methodname string) string {
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
pub fn (self Planning) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"calendar": {"name": "My Planning", "description": "A personal calendar", "color": "#FF0000", "timezone": "UTC", "is_public": true, "events": []}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "My Planning", "description": "A personal calendar", "color": "#FF0000", "timezone": "UTC", "is_public": true, "events": []}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "My Planning", "description": "A personal calendar", "color": "#FF0000", "timezone": "UTC", "is_public": true, "events": []}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Planning) dump(mut e encoder.Encoder) ! {
	e.add_string(self.color)
	e.add_string(self.timezone)
	e.add_bool(self.is_public)
}

fn (mut self DBPlanning) load(mut o Planning, mut e encoder.Decoder) ! {
	o.color = e.get_string()!
	o.timezone = e.get_string()!
	o.is_public = e.get_bool()!
}

@[params]
pub struct PlanningArg {
pub mut:
	name        string
	description string
	color       string
	timezone    string
	is_public   bool
	events      []u32
}

// get new calendar, not from the DB
pub fn (mut self DBPlanning) new(args PlanningArg) !Planning {
	mut o := Planning{
		color:     args.color
		timezone:  args.timezone
		is_public: args.is_public
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBPlanning) set(o Planning) !Planning {
	// Use db set function which returns the object with assigned ID
	return self.db.set[Planning](o)!
}

pub fn (mut self DBPlanning) delete(id u32) ! {
	self.db.delete[Planning](id)!
}

pub fn (mut self DBPlanning) exist(id u32) !bool {
	return self.db.exists[Planning](id)!
}

pub fn (mut self DBPlanning) get(id u32) !Planning {
	mut o, data := self.db.get_data[Planning](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBPlanning) list(args PlanningListArg) ![]Planning {
	// Require at least one parameter to be provided
	if !args.is_public {
		return error('At least one filter parameter must be provided')
	}

	// Get all calendars from the database
	all_calendars := self.db.list[Planning]()!.map(self.get(it)!)

	// Apply filters
	mut filtered_calendars := []Planning{}
	for calendar in all_calendars {
		// Filter by is_public if provided (is_public is true)
		if args.is_public && !calendar.is_public {
			continue
		}

		filtered_calendars << calendar
	}

	// Limit results to 100 or the specified limit
	mut limit := args.limit
	if limit > 100 {
		limit = 100
	}
	if filtered_calendars.len > limit {
		return filtered_calendars[..limit]
	}

	return filtered_calendars
}
