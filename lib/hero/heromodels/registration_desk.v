module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import json

@[heap]
pub struct RegistrationDesk {
	db.Base
pub mut:
	name                string
	description         string                       // probably in markdown
	fs_items            []RegistrationFileAttachment // link to docs
	white_list          []u32                        // users who can enter, if 1 specified then people need to be in this list
	white_list_accepted []u32                        // if in this list automatically accepted
	required_list       []u32                        // users who must be part of the event
	black_list          []u32                        // users not allowed
	start_time          u64  // time when users can start registration
	end_time            u64  // time when registration desk stops
	acceptance_required bool // if set then admins need to approve
	registrations       []Registration
}

pub struct Registration {
pub mut:
	user_id               u32
	accepted              bool // an administrator has accepted
	accepted_by           u32  // the user who did the acceptance
	timestamp             u64  // time when registration happened
	timestamp_acceptation u64  // when acceptation was done
}

pub struct RegistrationFileAttachment {
pub mut:
	fs_item u32
	cat     string // can be freely chosen, will always be made lowercase e.g. agenda
	public  bool   // everyone can see the file, otherwise only the organizers, attendees
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
			return '{"registration_desk": {"name": "event_registration", "description": "Registration desk for team meeting", "fs_items": [{"fs_item": 1001, "cat": "agenda", "public": true}], "white_list": [100, 101], "white_list_accepted": [102], "black_list": [200], "start_time": 1672564800, "end_time": 1672568400, "acceptance_required": true, "registrations": [{"user_id": 300, "accepted": true, "accepted_by": 400, "timestamp": 1672564900, "timestamp_acceptation": 1672565000}]}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "event_registration", "description": "Registration desk for team meeting", "fs_items": [{"fs_item": 1001, "cat": "agenda", "public": true}], "white_list": [100, 101], "white_list_accepted": [102], "black_list": [200], "start_time": 1672564800, "end_time": 1672568400, "acceptance_required": true, "registrations": [{"user_id": 300, "accepted": true, "accepted_by": 400, "timestamp": 1672564900, "timestamp_acceptation": 1672565000}]}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "event_registration", "description": "Registration desk for team meeting", "fs_items": [{"fs_item": 1001, "cat": "agenda", "public": true}], "white_list": [100, 101], "white_list_accepted": [102], "black_list": [200], "start_time": 1672564800, "end_time": 1672568400, "acceptance_required": true, "registrations": [{"user_id": 300, "accepted": true, "accepted_by": 400, "timestamp": 1672564900, "timestamp_acceptation": 1672565000}]}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self RegistrationDesk) dump(mut e encoder.Encoder) ! {
	e.add_string(self.name)
	e.add_string(self.description)

	// Encode fs_items array (RegistrationFileAttachment objects)
	e.add_u16(u16(self.fs_items.len))
	for fs_item in self.fs_items {
		e.add_u32(fs_item.fs_item)
		e.add_string(fs_item.cat)
		e.add_bool(fs_item.public)
	}

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

	// Decode fs_items array (RegistrationFileAttachment objects)
	fs_items_len := e.get_u16()!
	mut fs_items := []RegistrationFileAttachment{}
	for _ in 0 .. fs_items_len {
		fs_item := e.get_u32()!
		cat := e.get_string()!
		public := e.get_bool()!

		fs_items << RegistrationFileAttachment{
			fs_item: fs_item
			cat:     cat
			public:  public
		}
	}
	o.fs_items = fs_items

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
	name                string
	description         string
	fs_items            []u32  // IDs of linked files or dirs
	white_list          []u32  // users who can enter, if 1 specified then people need to be in this list
	white_list_accepted []u32  // if in this list automatically accepted
	black_list          []u32  // users not allowed
	start_time          string // use ourtime module to go from string to epoch
	end_time            string // use ourtime module to go from string to epoch
	acceptance_required bool   // if set then admins need to approve
	securitypolicy      u32
	tags                []string
	messages            []db.MessageArg
}

pub fn (mut self DBRegistrationDesk) new(args RegistrationDeskArg) !RegistrationDesk {
	// Convert fs_items from []u32 to []RegistrationFileAttachment
	mut fs_attachments := []RegistrationFileAttachment{}
	for fs_item_id in args.fs_items {
		fs_attachments << RegistrationFileAttachment{
			fs_item: fs_item_id
			cat:     ''
			public:  false
		}
	}

	mut o := RegistrationDesk{
		name:                args.name
		description:         args.description
		fs_items:            fs_attachments
		white_list:          args.white_list
		white_list_accepted: args.white_list_accepted
		black_list:          args.black_list
		acceptance_required: args.acceptance_required
		registrations:       []Registration{}
	}

	// Set base fields
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.messages = self.db.messages_get(args.messages)!
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

pub fn (mut self DBRegistrationDesk) delete(id u32) !bool {
	// Check if the item exists before trying to delete
	if !self.db.exists[RegistrationDesk](id)! {
		return false
	}
	self.db.delete[RegistrationDesk](id)!
	return true
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

pub fn registration_desk_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.registration_desk.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut o := db.decode_generic[RegistrationDesk](params)!
			o = f.registration_desk.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			deleted := f.registration_desk.delete(id)!
			if deleted {
				return new_response_true(rpcid)
			} else {
				return new_error(rpcid,
					code:    404
					message: 'Registration desk with ID ${id} not found'
				)
			}
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.registration_desk.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			args := db.decode_generic[RegistrationDeskListArg](params)!
			res := f.registration_desk.list(args)!
			return new_response(rpcid, json.encode(res))
		}
		else {
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on registration_desk'
			)
		}
	}
}
