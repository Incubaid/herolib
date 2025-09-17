module models_ledger

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// UserKVS represents a key-value store for a user
@[heap]
pub struct UserKVS {
	db.Base
pub mut:
	user_id u32 @[index]
}

pub struct DBUserKVS {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self UserKVS) type_name() string {
	return 'userkvs'
}

pub fn (self UserKVS) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a user KVS. Returns the ID of the KVS.'
		}
		'get' {
			return 'Retrieve a user KVS by ID. Returns the KVS object.'
		}
		'delete' {
			return 'Delete a user KVS by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a user KVS exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all user KVS. Returns an array of KVS objects.'
		}
		else {
			return 'User KVS management operations'
		}
	}
}

pub fn (self UserKVS) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"userkvs": {"user_id": 1}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"user_id": 1}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"user_id": 1}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self UserKVS) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.user_id)
}

fn (mut self DBUserKVS) load(mut o UserKVS, mut e encoder.Decoder) ! {
	o.user_id = e.get_u32()!
}

@[params]
pub struct UserKVSArg {
pub mut:
	name        string
	description string
	user_id     u32
}

pub fn (mut self DBUserKVS) new(args UserKVSArg) !UserKVS {
	mut o := UserKVS{
		user_id: args.user_id
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBUserKVS) set(o UserKVS) !UserKVS {
	return self.db.set[UserKVS](o)!
}

pub fn (mut self DBUserKVS) delete(id u32) ! {
	self.db.delete[UserKVS](id)!
}

pub fn (mut self DBUserKVS) exist(id u32) !bool {
	return self.db.exists[UserKVS](id)!
}

pub fn (mut self DBUserKVS) get(id u32) !UserKVS {
	mut o, data := self.db.get_data[UserKVS](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBUserKVS) list() ![]UserKVS {
	return self.db.list[UserKVS]()!.map(self.get(it)!)
}