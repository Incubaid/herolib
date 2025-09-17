// lib/threefold/models_ledger/account.v
module models_ledger

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// AccountStatus represents the status of an account
pub enum AccountStatus {
	active
	inactive
	suspended
	archived
}

// Account represents an account in the financial system
@[heap]
pub struct Account {
	db.Base
pub mut:
	owner_id       u32 //link to user
	location_id    u32 //link to location, 0 is none
	accountpolicies []AccountPolicy
	assets []AccountAsset
	assetid        u32
	last_activity  u64
	administrators []u32
}

// AccountPolicy represents a set of rules for an account

pub struct AccountPolicy {
pub mut:
	policy_id          	u32 @[index]
	admins 				[]u32 //people who can transfer money out
	min_signatures     	u8 //nr of people who need to sign
	limits 
	whitelist_out      	[]u32 //where money can go to
	whitelist_in 	   	[]u32 //where money can come from
	lock_till 			u64 //date in epoch till no money can be transfered, only after
	admin_lock_type 	LockType
	admin_lock_till 	u64 //date in epoch when admin can unlock (0 means its free), this is unlock for changing this policy
	admin_unlock 		[]u32 //users who can unlock the admin policy
	admin_unlock_min_signature u8 //nr of signatures from the adminunlock
}

pub enum LockType{
	locked_till
	locked
	free
}

pub struct AccountLimit {
pub mut:
	amount f64
	asset_id u32
	period AccountLimitPeriodLimit
}


pub enum AccountLimitPeriodLimit{
	daily
	weekly
	monthly
}


pub struct AccountAsset {
	db.Base
pub mut:
	assetid         u32
	balance        f64
	metadata        map[string]string 
}



pub struct DBAccount {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Account) type_name() string {
	return 'account'
}

pub fn (self Account) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update an account. Returns the ID of the account.'
		}
		'get' {
			return 'Retrieve an account by ID. Returns the account object.'
		}
		'delete' {
			return 'Delete an account by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if an account exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all accounts. Returns an array of account objects.'
		}
		else {
			return 'Account management operations'
		}
	}
}

pub fn (self Account) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"account": {"owner_id": 1, "address": "addr123", "balance": 1000.0, "currency": "USD", "assetid": 1}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"owner_id": 1, "address": "addr123", "balance": 1000.0, "currency": "USD", "assetid": 1}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"owner_id": 1, "address": "addr123", "balance": 1000.0, "currency": "USD", "assetid": 1}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Account) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.owner_id)
	e.add_string(self.address)
	e.add_f64(self.balance)
	e.add_string(self.currency)
	e.add_u32(self.assetid)
	e.add_u64(self.last_activity)
	e.add_list_u32(self.administrators)
	e.add_u32(self.accountpolicy)
}

fn (mut self DBAccount) load(mut o Account, mut e encoder.Decoder) ! {
	o.owner_id = e.get_u32()!
	o.address = e.get_string()!
	o.balance = e.get_f64()!
	o.currency = e.get_string()!
	o.assetid = e.get_u32()!
	o.last_activity = e.get_u64()!
	o.administrators = e.get_list_u32()!
	o.accountpolicy = e.get_u32()!
}

@[params]
pub struct AccountArg {
pub mut:
	name           string
	description    string
	owner_id       u32
	address        string
	balance        f64
	currency       string
	assetid        u32
	last_activity  u64
	administrators []u32
	accountpolicy  u32
}

pub fn (mut self DBAccount) new(args AccountArg) !Account {
	mut o := Account{
		owner_id:       args.owner_id
		address:        args.address
		balance:        args.balance
		currency:       args.currency
		assetid:        args.assetid
		last_activity:  args.last_activity
		administrators: args.administrators
		accountpolicy:  args.accountpolicy
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBAccount) set(o Account) !Account {
	return self.db.set[Account](o)!
}

pub fn (mut self DBAccount) delete(id u32) ! {
	self.db.delete[Account](id)!
}

pub fn (mut self DBAccount) exist(id u32) !bool {
	return self.db.exists[Account](id)!
}

pub fn (mut self DBAccount) get(id u32) !Account {
	mut o, data := self.db.get_data[Account](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBAccount) list() ![]Account {
	return self.db.list[Account]()!.map(self.get(it)!)
}