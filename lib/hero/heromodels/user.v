module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import json

// User represents a person in the system
@[heap]
pub struct User {
	db.Base
pub mut:
	user_id     u32 // id as is set in ledger, if 0 then we don't know
	contact_id  u32 // if we have separate content info for this person
	status      UserStatus
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
	e.add_u32(self.user_id)
	e.add_u32(self.contact_id)
	e.add_u8(u8(self.status))
	e.add_list_string(self.profile_ids)
}

fn (mut self DBUser) load(mut o User, mut e encoder.Decoder) ! {
	o.user_id = e.get_u32()!
	o.contact_id = e.get_u32()!
	o.status = unsafe { UserStatus(e.get_u8()!) }
	o.profile_ids = e.get_list_string()!
}

@[params]
pub struct UserArg {
pub mut:
	name           string @[required]
	description    string
	user_id        u32
	contact_id     u32
	status         UserStatus
	profile_ids    []string
	securitypolicy u32
	tags           []string
	messages       []db.MessageArg
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
		user_id:     args.user_id
		contact_id:  args.contact_id
		status:      args.status
		profile_ids: args.profile_ids
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

pub fn (mut self DBUser) set(o User) !User {
	return self.db.set[User](o)!
}

pub fn (mut self DBUser) delete(id u32) !bool {
	// Check if the item exists before trying to delete
	if !self.db.exists[User](id)! {
		return false
	}
	self.db.delete[User](id)!
	return true
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
	// Get all users from the database
	all_users := self.db.list[User]()!.map(self.get(it)!)

	// Apply filters - return all users if no specific status filter is provided
	mut filtered_users := []User{}
	for user in all_users {
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

pub fn user_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.user.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			args := db.decode_generic[UserArg](params)!
			mut o := f.user.new(args)!
			o = f.user.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			deleted := f.user.delete(id)!
			if deleted {
				return new_response_true(rpcid)
			} else {
				return new_error(rpcid,
					code:    404
					message: 'User with ID ${id} not found'
				)
			}
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.user.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			args := db.decode_generic[UserListArg](params)!
			res := f.user.list(args)!
			return new_response(rpcid, json.encode(res))
		}
		else {
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on user'
			)
		}
	}
}
