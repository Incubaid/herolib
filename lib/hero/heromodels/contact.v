module heromodels

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db
import incubaid.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_true }
import incubaid.herolib.hero.user { UserRef }
import json

// Contact represents a person in the system
@[heap]
pub struct Contact {
	db.Base
pub mut:
	emails      []string
	user_id     u32 // id as is set in ledger, if 0 then we don't know
	phones      []string
	addresses   []string
	avatar_url  string
	bio         string
	timezone    string
	status      ContactStatus
	profile_ids []u32
}

pub enum ContactStatus {
	active
	inactive
}

pub fn (self Contact) type_name() string {
	return 'contact'
}

// return example rpc call and result for each methodname
pub fn (self Contact) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a contact. Returns the ID of the contact.'
		}
		'get' {
			return 'Retrieve a contact by ID. Returns the contact object.'
		}
		'delete' {
			return 'Delete a contact by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a contact exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all contacts. Returns an array of contact objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self Contact) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"contact": {"name": "John Doe", "description": "A test contact", "email": "john.doe@example.com", "public_key": "some_public_key", "phone": "123-456-7890", "address": "123 Main St", "avatar_url": "https://example.com/avatar.jpg", "bio": "Software Engineer", "timezone": "UTC", "status": "active"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "John Doe", "description": "A test contact", "email": "john.doe@example.com", "public_key": "some_public_key", "phone": "123-456-7890", "address": "123 Main St", "avatar_url": "https://example.com/avatar.jpg", "bio": "Software Engineer", "timezone": "UTC", "status": "active"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "John Doe", "description": "A test contact", "email": "john.doe@example.com", "public_key": "some_public_key", "phone": "123-456-7890", "address": "123 Main St", "avatar_url": "https://example.com/avatar.jpg", "bio": "Software Engineer", "timezone": "UTC", "status": "active"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Contact) dump(mut e encoder.Encoder) ! {
	e.add_list_string(self.emails)
	e.add_u32(self.user_id)
	e.add_list_string(self.phones)
	e.add_list_string(self.addresses)
	e.add_string(self.avatar_url)
	e.add_string(self.bio)
	e.add_string(self.timezone)
	e.add_u8(u8(self.status))
}

fn (mut self DBContact) load(mut o Contact, mut e encoder.Decoder) ! {
	o.emails = e.get_list_string()!
	o.user_id = e.get_u32()!
	o.phones = e.get_list_string()!
	o.addresses = e.get_list_string()!
	o.avatar_url = e.get_string()!
	o.bio = e.get_string()!
	o.timezone = e.get_string()!
	o.status = unsafe { ContactStatus(e.get_u8()!) }
}

@[params]
pub struct ContactArg {
pub mut:
	id             u32
	name           string @[required]
	description    string
	emails         []string
	phones         []string
	addresses      []string
	avatar_url     string
	bio            string
	timezone       string
	status         ContactStatus
	securitypolicy u32
	tags           []string
	messages       []db.MessageArg
}

pub struct DBContact {
pub mut:
	db &db.DB @[skip; str: skip]
}

@[params]
pub struct ContactListArg {
pub mut:
	status ContactStatus
	limit  int = 100 // Default limit is 100
}

// get new contact, not from the DB
pub fn (mut self DBContact) new(args ContactArg) !Contact {
	mut o := Contact{
		emails:     args.emails
		phones:     args.phones
		addresses:  args.addresses
		avatar_url: args.avatar_url
		bio:        args.bio
		timezone:   args.timezone
		status:     args.status
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

pub fn (mut self DBContact) set(o Contact) !Contact {
	return self.db.set[Contact](o)!
}

pub fn (mut self DBContact) delete(id u32) !bool {
	// Check if the item exists before trying to delete
	if !self.db.exists[Contact](id)! {
		return false
	}
	self.db.delete[Contact](id)!
	return true
}

pub fn (mut self DBContact) exist(id u32) !bool {
	return self.db.exists[Contact](id)!
}

pub fn (mut self DBContact) get(id u32) !Contact {
	mut o, data := self.db.get_data[Contact](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBContact) list(args ContactListArg) ![]Contact {
	// Get all contacts from the database
	all_contacts := self.db.list[Contact]()!.map(self.get(it)!)

	// Apply filters - return all contacts if no specific status filter is provided
	mut filtered_contacts := []Contact{}
	for contact in all_contacts {
		filtered_contacts << contact
	}

	// Limit results to 100 or the specified limit
	mut limit := args.limit
	if limit > 100 {
		limit = 100
	}
	if filtered_contacts.len > limit {
		return filtered_contacts[..limit]
	}

	return filtered_contacts
}

pub fn contact_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.contact.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut args := db.decode_generic[ContactArg](params)!
			mut o := f.contact.new(args)!
			if args.id != 0 {
				o.id = args.id
			}
			o = f.contact.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			deleted := f.contact.delete(id)!
			if deleted {
				return new_response_true(rpcid)
			} else {
				return new_error(rpcid,
					code:    404
					message: 'Contact with ID ${id} not found'
				)
			}
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.contact.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			args := db.decode_generic[ContactListArg](params)!
			res := f.contact.list(args)!
			return new_response(rpcid, json.encode(res))
		}
		else {
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on contact'
			)
		}
	}
}
