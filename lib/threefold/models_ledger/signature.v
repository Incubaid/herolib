module models_ledger

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db

// Signature represents a digital signature in the system
@[heap]
pub struct Signature {
	db.Base
pub mut:
	signer_id u32 @[index]
	tx_id     u32 @[index]
	signature string
	timestamp u64
}

pub struct DBSignature {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Signature) type_name() string {
	return 'signature'
}

pub fn (self Signature) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a signature. Returns the ID of the signature.'
		}
		'get' {
			return 'Retrieve a signature by ID. Returns the signature object.'
		}
		'delete' {
			return 'Delete a signature by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a signature exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all signatures. Returns an array of signature objects.'
		}
		else {
			return 'Signature management operations'
		}
	}
}

pub fn (self Signature) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"signature": {"signer_id": 1, "tx_id": 123, "signature": "hex_encoded_signature"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"signer_id": 1, "tx_id": 123, "signature": "hex_encoded_signature"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"signer_id": 1, "tx_id": 123, "signature": "hex_encoded_signature"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Signature) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.signer_id)
	e.add_u32(self.tx_id)
	e.add_string(self.signature)
	e.add_u64(self.timestamp)
}

fn (mut self DBSignature) load(mut o Signature, mut e encoder.Decoder) ! {
	o.signer_id = e.get_u32()!
	o.tx_id = e.get_u32()!
	o.signature = e.get_string()!
	o.timestamp = e.get_u64()!
}

@[params]
pub struct SignatureArg {
pub mut:
	name        string
	description string
	signer_id   u32
	tx_id       u32
	signature   string
}

pub fn (mut self DBSignature) new(args SignatureArg) !Signature {
	mut o := Signature{
		signer_id: args.signer_id
		tx_id:     args.tx_id
		signature: args.signature
		timestamp: u64(ourtime.now().unix())
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBSignature) set(o Signature) !Signature {
	return self.db.set[Signature](o)!
}

pub fn (mut self DBSignature) delete(id u32) ! {
	self.db.delete[Signature](id)!
}

pub fn (mut self DBSignature) exist(id u32) !bool {
	return self.db.exists[Signature](id)!
}

pub fn (mut self DBSignature) get(id u32) !Signature {
	mut o, data := self.db.get_data[Signature](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBSignature) list() ![]Signature {
	return self.db.list[Signature]()!.map(self.get(it)!)
}
