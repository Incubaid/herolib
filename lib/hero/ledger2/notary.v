module ledger

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db

// Notary represents a cryptographic notary in the system
@[heap]
pub struct Notary {
	db.Base
pub mut:
	notary_id u32 @[index]
	pubkey    string
	address   string
	is_active bool
}

pub struct DBNotary {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Notary) type_name() string {
	return 'notary'
}

pub fn (self Notary) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a notary. Returns the ID of the notary.'
		}
		'get' {
			return 'Retrieve a notary by ID. Returns the notary object.'
		}
		'delete' {
			return 'Delete a notary by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a notary exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all notaries. Returns an array of notary objects.'
		}
		else {
			return 'Notary management operations'
		}
	}
}

pub fn (self Notary) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"notary": {"notary_id": 1, "pubkey": "ed25519_pubkey", "address": "TFT_ADDRESS_XYZ", "is_active": true}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"notary_id": 1, "pubkey": "ed25519_pubkey", "address": "TFT_ADDRESS_XYZ", "is_active": true}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"notary_id": 1, "pubkey": "ed25519_pubkey", "address": "TFT_ADDRESS_XYZ", "is_active": true}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Notary) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.notary_id)
	e.add_string(self.pubkey)
	e.add_string(self.address)
	e.add_bool(self.is_active)
}

fn (mut self DBNotary) load(mut o Notary, mut e encoder.Decoder) ! {
	o.notary_id = e.get_u32()!
	o.pubkey = e.get_string()!
	o.address = e.get_string()!
	o.is_active = e.get_bool()!
}

@[params]
pub struct NotaryArg {
pub mut:
	name        string
	description string
	notary_id   u32
	pubkey      string
	address     string
	is_active   bool = true
}

pub fn (mut self DBNotary) new(args NotaryArg) !Notary {
	mut o := Notary{
		notary_id: args.notary_id
		pubkey:    args.pubkey
		address:   args.address
		is_active: args.is_active
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBNotary) set(o Notary) !Notary {
	return self.db.set[Notary](o)!
}

pub fn (mut self DBNotary) delete(id u32) ! {
	self.db.delete[Notary](id)!
}

pub fn (mut self DBNotary) exist(id u32) !bool {
	return self.db.exists[Notary](id)!
}

pub fn (mut self DBNotary) get(id u32) !Notary {
	mut o, data := self.db.get_data[Notary](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBNotary) list() ![]Notary {
	return self.db.list[Notary]()!.map(self.get(it)!)
}
