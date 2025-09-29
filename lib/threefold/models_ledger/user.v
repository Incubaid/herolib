// lib/threefold/models_ledger/user.v
module models_ledger

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// User represents a user in the heroledger system
@[heap]
pub struct User {
	db.Base
pub mut:
	username    string @[index]
	pubkey      string @[index]
	email       []string
	status      UserStatus
	userprofile []SecretBox
	kyc         []SecretBox
}

// UserStatus represents the status of a user in the system
pub enum UserStatus {
	active
	inactive
	suspended
	archived
}

// KYCStatus represents the KYC status of a user
pub enum KYCStatus {
	pending
	approved
	rejected
}

// UserProfile contains user profile information
pub struct UserProfile {
pub mut:
	user_id     u32
	full_name   string
	bio         string
	profile_pic string
	links       map[string]string
	metadata    map[string]string
}

// KYCInfo contains KYC information for a user
pub struct KYCInfo {
pub mut:
	user_id             u32
	full_name           string
	date_of_birth       u64
	address             string
	phone_number        string
	id_number           string
	id_type             string
	id_expiry           u64
	kyc_status          KYCStatus
	kyc_verified        bool
	kyc_verified_by     u32
	kyc_verified_at     u64
	kyc_rejected_reason string
	kyc_signature       u32
	metadata            map[string]string
}

// SecretBox represents encrypted data storage
pub struct SecretBox {
pub mut:
	data  []u8
	nonce []u8
}

pub struct DBUser {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self User) type_name() string {
	return 'user'
}

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
			return 'User management operations'
		}
	}
}

pub fn (self User) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"user": {"username": "alice", "pubkey": "ed25519_pubkey_here", "email": ["alice@example.com"], "status": "active"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"username": "alice", "pubkey": "ed25519_pubkey_here", "email": ["alice@example.com"], "status": "active"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"username": "alice", "pubkey": "ed25519_pubkey_here", "email": ["alice@example.com"], "status": "active"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self User) dump(mut e encoder.Encoder) ! {
	e.add_string(self.username)
	e.add_string(self.pubkey)
	e.add_list_string(self.email)
	e.add_int(int(self.status))
	e.add_int(self.userprofile.len)
	for profile in self.userprofile {
		e.add_list_u8(profile.data)
		e.add_list_u8(profile.nonce)
	}
	e.add_int(self.kyc.len)
	for kyc_item in self.kyc {
		e.add_list_u8(kyc_item.data)
		e.add_list_u8(kyc_item.nonce)
	}
}

fn (mut self DBUser) load(mut o User, mut e encoder.Decoder) ! {
	o.username = e.get_string()!
	o.pubkey = e.get_string()!
	o.email = e.get_list_string()!
	o.status = unsafe { UserStatus(e.get_int()!) }

	profile_len := e.get_int()!
	o.userprofile = []SecretBox{cap: profile_len}
	for _ in 0 .. profile_len {
		profile := SecretBox{
			data:  e.get_list_u8()!
			nonce: e.get_list_u8()!
		}
		o.userprofile << profile
	}

	kyc_len := e.get_int()!
	o.kyc = []SecretBox{cap: kyc_len}
	for _ in 0 .. kyc_len {
		kyc_item := SecretBox{
			data:  e.get_list_u8()!
			nonce: e.get_list_u8()!
		}
		o.kyc << kyc_item
	}
}

@[params]
pub struct UserArg {
pub mut:
	name        string
	description string
	username    string
	pubkey      string
	email       []string
	status      UserStatus
	userprofile []SecretBox
	kyc         []SecretBox
}

pub fn (mut self DBUser) new(args UserArg) !User {
	mut o := User{
		username:    args.username
		pubkey:      args.pubkey
		email:       args.email
		status:      args.status
		userprofile: args.userprofile
		kyc:         args.kyc
	}

	o.name = args.name
	o.description = args.description
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

pub fn (mut self DBUser) list() ![]User {
	return self.db.list[User]()!.map(self.get(it)!)
}
