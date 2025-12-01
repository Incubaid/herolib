// lib/threefold/models_ledger/transaction.v
module models_ledger

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db

// Transaction represents a financial transaction
@[heap]
pub struct Transaction {
	db.Base
pub mut:
	txid        u32
	source      u32
	destination u32
	assetid     u32
	amount      u64
	timestamp   u64
	status      string
	memo        string
	tx_type     TransactionType
	signatures  []TransactionSignature
}

// TransactionType represents the type of transaction
pub enum TransactionType {
	transfer
	clawback
	freeze
	unfreeze
	issue
	burn
}

// TransactionSignature represents a signature for transactions
pub struct TransactionSignature {
pub mut:
	signer_id u32
	signature string
	timestamp u64
}

pub struct DBTransaction {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Transaction) type_name() string {
	return 'transaction'
}

pub fn (self Transaction) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a transaction. Returns the ID of the transaction.'
		}
		'get' {
			return 'Retrieve a transaction by ID. Returns the transaction object.'
		}
		'delete' {
			return 'Delete a transaction by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a transaction exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all transactions. Returns an array of transaction objects.'
		}
		else {
			return 'Transaction management operations'
		}
	}
}

pub fn (self Transaction) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"transaction": {"txid": 1, "source": 1, "destination": 2, "assetid": 1, "amount": 100.0, "status": "completed", "tx_type": "transfer"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"txid": 1, "source": 1, "destination": 2, "assetid": 1, "amount": 100.0, "status": "completed", "tx_type": "transfer"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"txid": 1, "source": 1, "destination": 2, "assetid": 1, "amount": 100.0, "status": "completed", "tx_type": "transfer"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Transaction) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.txid)
	e.add_u32(self.source)
	e.add_u32(self.destination)
	e.add_u32(self.assetid)
	e.add_u64(self.amount)
	e.add_u64(self.timestamp)
	e.add_string(self.status)
	e.add_string(self.memo)
	e.add_int(int(self.tx_type))

	// signatures
	e.add_int(self.signatures.len)
	for sig in self.signatures {
		e.add_u32(sig.signer_id)
		e.add_string(sig.signature)
		e.add_u64(sig.timestamp)
	}
}

fn (mut self DBTransaction) load(mut o Transaction, mut e encoder.Decoder) ! {
	o.txid = e.get_u32()!
	o.source = e.get_u32()!
	o.destination = e.get_u32()!
	o.assetid = e.get_u32()!
	o.amount = e.get_u64()!
	o.timestamp = e.get_u64()!
	o.status = e.get_string()!
	o.memo = e.get_string()!
	o.tx_type = unsafe { TransactionType(e.get_int()!) }

	// signatures
	sig_len := e.get_int()!
	o.signatures = []TransactionSignature{cap: sig_len}
	for _ in 0 .. sig_len {
		sig := TransactionSignature{
			signer_id: e.get_u32()!
			signature: e.get_string()!
			timestamp: e.get_u64()!
		}
		o.signatures << sig
	}
}

@[params]
pub struct TransactionArg {
pub mut:
	name        string
	description string
	txid        u32
	source      u32
	destination u32
	assetid     u32
	amount      u64
	timestamp   u64
	status      string
	memo        string
	tx_type     TransactionType
	signatures  []TransactionSignature
}

pub fn (mut self DBTransaction) new(args TransactionArg) !Transaction {
	mut o := Transaction{
		txid:        args.txid
		source:      args.source
		destination: args.destination
		assetid:     args.assetid
		amount:      args.amount
		timestamp:   args.timestamp
		status:      args.status
		memo:        args.memo
		tx_type:     args.tx_type
		signatures:  args.signatures
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBTransaction) set(o Transaction) !Transaction {
	return self.db.set[Transaction](o)!
}

pub fn (mut self DBTransaction) delete(id u32) ! {
	self.db.delete[Transaction](id)!
}

pub fn (mut self DBTransaction) exist(id u32) !bool {
	return self.db.exists[Transaction](id)!
}

pub fn (mut self DBTransaction) get(id u32) !Transaction {
	mut o, data := self.db.get_data[Transaction](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBTransaction) list() ![]Transaction {
	return self.db.list[Transaction]()!.map(self.get(it)!)
}
