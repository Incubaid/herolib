module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Planning, how do people or teams want to plan their time
//acls can be used to define who can change this planning
@[heap]
pub struct Planning {
	db.Base
pub mut:
	color              string // Hex color code
	timezone           string
	is_public          bool
	calendar_template_id        u32              // link to calendarid which is relevant for this planning, this calendar event will be a template
	registration_desk_id u32 //to arrange how we let people register, and track registrations
	autoschedule_rules []RecurrenceRule // will automatically schedule, uses calendar_id as template
	invite_rules       []RecurrenceRule // times in which people can invite themselves
	attendees_required []u32 
	attendees_optional []u32 //if we want to specify upfront
}

pub struct RecurrenceRule {
pub mut:
	// cron        string // in linux cron format, if cron used then other ones below not used
	until       u64  // End date (Unix timestamp)
	by_weekday  []u8 // Days of week (0=Sunday)
	by_monthday []u8 // Days of month
	hour_from   u8   // starts at midnight e.g. 10
	hour_to     u8   // e.g. 12 means between 10 and 12 (noon)
	duration    int  // in minutes e.g. 30, means half hour
	priority    u8   // to tell user what has our preference, higher nr is better, max 10
}



pub fn (self RecurrenceRule) dump(mut e encoder.Encoder) ! {
	e.add_u64(self.until)
	e.add_list_u8(self.by_weekday)
	e.add_list_u8(self.by_monthday)
	e.add_u8(self.hour_from)
	e.add_u8(self.hour_to)
	e.add_int(self.duration)
	e.add_u8(self.priority)
}

pub fn (mut self RecurrenceRule) load(mut e encoder.Decoder) ! {
	self.until = e.get_u64()!
	self.by_weekday = e.get_list_u8()!
	self.by_monthday = e.get_list_u8()!
	self.hour_from = e.get_u8()!
	self.hour_to = e.get_u8()!
	self.duration = e.get_int()!
	self.priority = e.get_u8()!
}

pub struct DBPlanning {
pub mut:
	db &db.DB @[skip; str: skip]
}

@[params]
pub struct PlanningListArg {
pub mut:
	is_public            bool
	calendar_template_id u32
	registration_desk_id u32
	limit                int = 100 // Default limit is 100
}

pub fn (self Planning) type_name() string {
	return 'planning'
}

// return example rpc call and result for each methodname
pub fn (self Planning) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a planning. Returns the ID of the planning.'
		}
		'get' {
			return 'Retrieve a planning by ID. Returns the planning object.'
		}
		'delete' {
			return 'Delete a planning by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a planning exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all plannings. Returns an array of planning objects.'
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
			return '{"planning": {"name": "My Planning", "description": "A personal planning", "color": "#FF0000", "timezone": "UTC", "is_public": true, "calendar_template_id": 1, "registration_desk_id": 10, "autoschedule_rules": [], "invite_rules": [], "attendees_required": [], "attendees_optional": []}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "My Planning", "description": "A personal planning", "color": "#FF0000", "timezone": "UTC", "is_public": true, "calendar_template_id": 1, "registration_desk_id": 10, "autoschedule_rules": [], "invite_rules": [], "attendees_required": [], "attendees_optional": []}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "My Planning", "description": "A personal planning", "color": "#FF0000", "timezone": "UTC", "is_public": true, "calendar_template_id": 1, "registration_desk_id": 10, "autoschedule_rules": [], "invite_rules": [], "attendees_required": [], "attendees_optional": []}]'
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
	e.add_u32(self.calendar_template_id)
	e.add_u32(self.registration_desk_id)
	
	// Encode autoschedule_rules array
	e.add_u16(u16(self.autoschedule_rules.len))
	for rule in self.autoschedule_rules {
		rule.dump(mut e)!
	}
	
	// Encode invite_rules array
	e.add_u16(u16(self.invite_rules.len))
	for rule in self.invite_rules {
		rule.dump(mut e)!
	}

	// Encode attendees_required array
	e.add_list_u32(self.attendees_required)

	// Encode attendees_optional array
	e.add_list_u32(self.attendees_optional)
}

fn (mut self DBPlanning) load(mut o Planning, mut e encoder.Decoder) ! {
	o.color = e.get_string()!
	o.timezone = e.get_string()!
	o.is_public = e.get_bool()!
	o.calendar_template_id = e.get_u32()!
	o.registration_desk_id = e.get_u32()!
	
	// Decode autoschedule_rules array
	autoschedule_rules_len := e.get_u16()!
	mut autoschedule_rules := []RecurrenceRule{}
	for _ in 0 .. autoschedule_rules_len {
		mut rule := RecurrenceRule{}
		rule.load(mut e)!
		autoschedule_rules << rule
	}
	o.autoschedule_rules = autoschedule_rules
	
	// Decode invite_rules array
	invite_rules_len := e.get_u16()!
	mut invite_rules := []RecurrenceRule{}
	for _ in 0 .. invite_rules_len {
		mut rule := RecurrenceRule{}
		rule.load(mut e)!
		invite_rules << rule
	}
	o.invite_rules = invite_rules

	// Decode attendees_required array
	o.attendees_required = e.get_list_u32()!

	// Decode attendees_optional array
	o.attendees_optional = e.get_list_u32()!
}

@[params]
pub struct PlanningArg {
pub mut:
	name                 string
	description          string
	color                string
	timezone             string
	is_public            bool
	calendar_template_id u32
	registration_desk_id u32
	autoschedule_rules   []RecurrenceRule
	invite_rules         []RecurrenceRule
	attendees_required   []u32
	attendees_optional   []u32
	securitypolicy       u32
	tags                 []string
	comments             []db.CommentArg
}

// get new calendar, not from the DB
pub fn (mut self DBPlanning) new(args PlanningArg) !Planning {
	mut o := Planning{
		color:                args.color
		timezone:             args.timezone
		is_public:            args.is_public
		calendar_template_id: args.calendar_template_id
		registration_desk_id: args.registration_desk_id
		autoschedule_rules:   args.autoschedule_rules
		invite_rules:         args.invite_rules
		attendees_required:   args.attendees_required
		attendees_optional:   args.attendees_optional
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
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
	// Require at least one parameter to be provided
	if !args.is_public && args.calendar_template_id == 0 && args.registration_desk_id == 0 {
		return error('At least one filter parameter must be provided')
	}

	// Get all plannings from the database
	all_plannings := self.db.list[Planning]()!.map(self.get(it)!)

	// Apply filters
	mut filtered_plannings := []Planning{}
	for planning in all_plannings {
		// Filter by is_public if provided
		if args.is_public && !planning.is_public {
			continue
		}

		// Filter by calendar_template_id if provided
		if args.calendar_template_id != 0 && planning.calendar_template_id != args.calendar_template_id {
			continue
		}

		// Filter by registration_desk_id if provided
		if args.registration_desk_id != 0 && planning.registration_desk_id != args.registration_desk_id {
			continue
		}

		filtered_plannings << planning
	}

	// Limit results to 100 or the specified limit
	mut limit := args.limit
	if limit > 100 {
		limit = 100
	}
	if filtered_plannings.len > limit {
		return filtered_plannings[..limit]
	}

	return filtered_plannings
}
