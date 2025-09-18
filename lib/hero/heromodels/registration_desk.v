module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db


@[heap]
pub struct RegistrationDesk {
	db.Base	
pub mut:
	name                string
	description         string //probably in markdown
	fs_items            []u32 // link to docs
	white_list          []u32 // users who can enter, if 1 specified then people need to be in this list
	white_list_accepted []u32 // if in this list automatically accepted
	black_list          []u32 // users not allowed
	start_time          u64   // time when users can start registration
	end_time            u64   // time when registration desk stops
	acceptance_required bool  // if set then admins need to approve
	registrations       []Registration
}

pub struct Registration {
pub mut:
	user_id               u32
	accepted              bool // an administrator needs to accept this person, now becomes an attendee
	accepted_by           u32  // the user who did the acceptance
	timestamp             u64  // time when registration happened
	timestamp_acceptation u64  // when acceptation was done
}

pub struct DBRegistrationDesk {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self RegistrationDesk) type_name() string {
	return 'registration_desk'
}

// return example rpc call and result for each methodname
pub fn (self RegistrationDesk) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a registration desk. Returns the ID of the registration desk.'
		}
		'get' {
			return 'Retrieve a registration desk by ID. Returns the registration desk object.'
		}
		'delete' {
			return 'Delete a registration desk by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a registration desk exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all registration desks. Returns an array of registration desk objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname, so example for call and the result
pub fn (self RegistrationDesk) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"registration_desk": {"name": "event_registration", "description": "Registration desk for team meeting", "fs_items": [], "white_list": [], "white_list_accepted": [], "black_list": [], "start_time": 1672564800, "end_time": 1672568400, "acceptance_required": true, "registrations": []}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "event_registration", "description": "Registration desk for team meeting", "fs_items": [], "white_list": [], "white_list_accepted": [], "black_list": [], "start_time": 1672564800, "end_time": 1672568400, "acceptance_required": true, "registrations": []}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "event_registration", "description": "Registration desk for team meeting", "fs_items": [], "white_list": [], "white_list_accepted": [], "black_list": [], "start_time": 1672564800, "end_time": 1672568400, "acceptance_required": true, "registrations": []}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self RegistrationDesk) dump(mut e encoder.Encoder) ! {
	e.add_string(self.name)
	e.add_string(self.description)
	e.add_list_u32(self.fs_items)
	e.add_list_u32(self.white_list)
	e.add_list_u32(self.white_list_accepted)
	e.add_list_u32(self.black_list)
	e.add_u64(self.start_time)
	e.add_u64(self.end_time)
	e.add_bool(self.acceptance_required)

	// Encode registrations array
	e.add_u16(u16(self.registrations.len))
	for registration in self.registrations {
		e.add_u32(registration.user_id)
		e.add_bool(registration.accepted)
		e.add_u32(registration.accepted_by)
		e.add_u64(registration.timestamp)
		e.add_u64(registration.timestamp_acceptation)
	}
}

pub fn (mut self DBRegistrationDesk) load(mut o RegistrationDesk, mut e encoder.Decoder) ! {
	o.name = e.get_string()!
	o.description = e.get_string()!
	o.fs_items = e.get_list_u32()!
	o.white_list = e.get_list_u32()!
	o.white_list_accepted = e.get_list_u32()!
	o.black_list = e.get_list_u32()!
	o.start_time = e.get_u64()!
	o.end_time = e.get_u64()!
	o.acceptance_required = e.get_bool()!

	// Decode registrations array
	registrations_len := e.get_u16()!
	mut registrations := []Registration{}
	for _ in 0 .. registrations_len {
		user_id := e.get_u32()!
		accepted := e.get_bool()!
		accepted_by := e.get_u32()!
		timestamp := e.get_u64()!
		timestamp_acceptation := e.get_u64()!

		registrations << Registration{
			user_id:               user_id
			accepted:              accepted
			accepted_by:           accepted_by
			timestamp:             timestamp
			timestamp_acceptation: timestamp_acceptation
		}
	}
	o.registrations = registrations
}

@[params]
pub struct RegistrationDeskArg {
pub mut:
	name               string
	description        string
	fs_items           []u32 // IDs of linked files or dirs
	white_list         []u32 // users who can enter, if 1 specified then people need to be in this list
	white_list_accepted []u32 // if in this list automatically accepted
	black_list         []u32 // users not allowed
	start_time         string // use ourtime module to go from string to epoch
	end_time           string // use ourtime module to go from string to epoch
	acceptance_required bool  // if set then admins need to approve
	securitypolicy     u32
	tags               []string
	comments           []db.CommentArg
}

pub fn (mut self DBRegistrationDesk) new(args RegistrationDeskArg) !RegistrationDesk {
	mut o := RegistrationDesk{
		name:               args.name
		description:        args.description
		fs_items:           args.fs_items
		white_list:         args.white_list
		white_list_accepted: args.white_list_accepted
		black_list:         args.black_list
		acceptance_required: args.acceptance_required
		registrations:      []Registration{}
	}

	// Set base fields
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
	o.updated_at = ourtime.now().unix()

	// Convert string times to Unix timestamps
	mut start_time_obj := ourtime.new(args.start_time)!
	o.start_time = u64(start_time_obj.unix())

	mut end_time_obj := ourtime.new(args.end_time)!
	o.end_time = u64(end_time_obj.unix())

	return o
}

pub fn (mut self DBRegistrationDesk) set(o RegistrationDesk) !RegistrationDesk {
	// Use db set function which returns the object with assigned ID
	return self.db.set[RegistrationDesk](o)!
}

pub fn (mut self DBRegistrationDesk) delete(id u32) ! {
	self.db.delete[RegistrationDesk](id)!
}

pub fn (mut self DBRegistrationDesk) exist(id u32) !bool {
	return self.db.exists[RegistrationDesk](id)!
}

pub fn (mut self DBRegistrationDesk) get(id u32) !RegistrationDesk {
	mut o, data := self.db.get_data[RegistrationDesk](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

@[params]
pub struct RegistrationDeskListArg {
pub mut:
	name        string
	description string
	limit       int = 100 // Default limit is 100
}

pub fn (mut self DBRegistrationDesk) list(args RegistrationDeskListArg) ![]RegistrationDesk {
	// Require at least one parameter to be provided
	if args.name == '' && args.description == '' {
		return error('At least one filter parameter must be provided')
	}

	// Get all registration desks from the database
	all_desks := self.db.list[RegistrationDesk]()!.map(self.get(it)!)

	// Apply filters
	mut filtered_desks := []RegistrationDesk{}
	for desk in all_desks {
		// Filter by name if provided
		if args.name != '' && desk.name != args.name {
			continue
		}

		// Filter by description if provided
		if args.description != '' && !desk.description.contains(args.description) {
			continue
		}

		filtered_desks << desk
	}

	// Limit results to 100 or the specified limit
	mut limit := args.limit
	if limit > 100 {
		limit = 100
	}
	if filtered_desks.len > limit {
		return filtered_desks[..limit]
	}

	return filtered_desks
}
