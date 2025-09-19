module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// User represents a person in the system
@[heap]
pub struct User {
	db.Base
pub mut:
	user_id    u32 // id as is set in ledger, if 0 then we don't know
	contact_id u32 // if we have separate content info for this person
	status     UserStatus
	profile_ids []string
}

pub enum UserStatus {
	active
	inactive
	suspended
	pending
}

pub fn (self User) type_name() string {
	return 'user'
}

// return example rpc call and result for each methodname
pub fn (self User) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a user. Returns the ID of the user.'
		}
		'get' {
			return 'Retrieve a user by ID. Returns the user object.'
		}
		'delete' {
			return 'Delete a user by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a user exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all users. Returns an array of user objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self User) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"user": {"name": "John Doe", "description": "A test user", "email": "john.doe@example.com", "public_key": "some_public_key", "phone": "123-456-7890", "address": "123 Main St", "avatar_url": "https://example.com/avatar.jpg", "bio": "Software Engineer", "timezone": "UTC", "status": "active"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "John Doe", "description": "A test user", "email": "john.doe@example.com", "public_key": "some_public_key", "phone": "123-456-7890", "address": "123 Main St", "avatar_url": "https://example.com/avatar.jpg", "bio": "Software Engineer", "timezone": "UTC", "status": "active"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "John Doe", "description": "A test user", "email": "john.doe@example.com", "public_key": "some_public_key", "phone": "123-456-7890", "address": "123 Main St", "avatar_url": "https://example.com/avatar.jpg", "bio": "Software Engineer", "timezone": "UTC", "status": "active"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self User) dump(mut e encoder.Encoder) ! {
	e.add_string(self.email)
	e.add_string(self.public_key)
	e.add_string(self.phone)
	e.add_string(self.address)
	e.add_string(self.avatar_url)
	e.add_string(self.bio)
	e.add_string(self.timezone)
	e.add_u8(u8(self.status))
}

fn (mut self DBUser) load(mut o User, mut e encoder.Decoder) ! {
	o.email = e.get_string()!
	o.public_key = e.get_string()!
	o.phone = e.get_string()!
	o.address = e.get_string()!
	o.avatar_url = e.get_string()!
	o.bio = e.get_string()!
	o.timezone = e.get_string()!
	o.status = unsafe { UserStatus(e.get_u8()!) }
}

@[params]
pub struct UserArg {
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
	status         UserStatus
	securitypolicy u32
	tags           u32
	messages       []u32
}

pub struct DBUser {
pub mut:
	db &db.DB @[skip; str: skip]
}

@[params]
pub struct UserListArg {
pub mut:
	status UserStatus
	limit  int = 100 // Default limit is 100
}

// get new user, not from the DB
pub fn (mut self DBUser) new(args UserArg) !User {
	mut o := User{
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

pub fn (mut self DBUser) set(o User) !User {
	return self.db.set[User](o)!
}

pub fn (mut self DBUser) delete(id u32) ! {
	self.db.delete[User](id)!
}

pub fn (mut self DBUser) exist(id u32) !bool {
	return self.db.exists[User](id)!
}

pub fn (mut self DBUser) get(id u32) !User {
	mut o, data := self.db.get_data[User](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBUser) list(args UserListArg) ![]User {
	// Require at least one parameter to be provided
	if args.status == .active {
		return error('At least one filter parameter must be provided')
	}

	// Get all users from the database
	all_users := self.db.list[User]()!.map(self.get(it)!)

	// Apply filters
	mut filtered_users := []User{}
	for user in all_users {
		// Filter by status if provided (status is not active)
		if args.status != .active && user.status != args.status {
			continue
		}

		filtered_users << user
	}

	// Limit results to 100 or the specified limit
	mut limit := args.limit
	if limit > 100 {
		limit = 100
	}
	if filtered_users.len > limit {
		return filtered_users[..limit]
	}

	return filtered_users
}
