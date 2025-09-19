module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Contact represents a person in the system
@[heap]
pub struct Contact {
	db.Base
pub mut:
	email      string
	user_id    u32 // id as is set in ledger, if 0 then we don't know
	phone      string
	address    string
	avatar_url string
	bio        string
	timezone   string
	status     ContactStatus
	profile_ids []string
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
	e.add_string(self.email)
	e.add_string(self.public_key)
	e.add_string(self.phone)
	e.add_string(self.address)
	e.add_string(self.avatar_url)
	e.add_string(self.bio)
	e.add_string(self.timezone)
	e.add_u8(u8(self.status))
}

fn (mut self DBContact) load(mut o Contact, mut e encoder.Decoder) ! {
	o.email = e.get_string()!
	o.public_key = e.get_string()!
	o.phone = e.get_string()!
	o.address = e.get_string()!
	o.avatar_url = e.get_string()!
	o.bio = e.get_string()!
	o.timezone = e.get_string()!
	o.status = unsafe { ContactStatus(e.get_u8()!) }
}

@[params]
pub struct ContactArg {
pub mut:
	name           string @[required]
	description    string
	email          string
	public_key     string // for encryption/signing
	phone          string
	address        string
	avatar_url     string
	bio            string
	timezone       string
	status         ContactStatus
	securitypolicy u32
	tags           u32
	messages       []u32
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
		email:      args.email
		public_key: args.public_key
		phone:      args.phone
		address:    args.address
		avatar_url: args.avatar_url
		bio:        args.bio
		timezone:   args.timezone
		status:     args.status
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = args.tags
	o.messages = args.messages
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBContact) set(o Contact) !Contact {
	return self.db.set[Contact](o)!
}

pub fn (mut self DBContact) delete(id u32) ! {
	self.db.delete[Contact](id)!
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
	// Require at least one parameter to be provided
	if args.status == .active {
		return error('At least one filter parameter must be provided')
	}

	// Get all contacts from the database
	all_contacts := self.db.list[Contact]()!.map(self.get(it)!)

	// Apply filters
	mut filtered_contacts := []Contact{}
	for contact in all_contacts {
		// Filter by status if provided (status is not active)
		if args.status != .active && contact.status != args.status {
			continue
		}

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
