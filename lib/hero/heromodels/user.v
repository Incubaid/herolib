module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// User represents a person in the system
@[heap]
pub struct User {
	db.Base
pub mut:
	email      string
	public_key string // for encryption/signing
	phone      string
	address    string
	avatar_url string
	bio        string
	timezone   string
	status     UserStatus
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
	comments       []u32
}

pub struct DBUser {
pub mut:
	db &db.DB @[skip; str: skip]
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
	o.comments = args.comments
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBUser) set(o User) !u32 {
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

pub fn (mut self DBUser) list() ![]User {
	return self.db.list[User]()!.map(self.get(it)!)
}
