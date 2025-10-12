// lib/threefold/models_ledger/account.v
module models_ledger

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db

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
	owner_id        u32 // link to user
	location_id     u32 // link to location, 0 is none
	accountpolicies []AccountPolicy
	assets          []AccountAsset
	assetid         u32
	last_activity   u64
	administrators  []u32
}

// AccountPolicy represents a set of rules for an account

pub struct AccountPolicy {
pub mut:
	policy_id                  u32 @[index]
	admins                     []u32 // people who can transfer money out
	min_signatures             u8    // nr of people who need to sign
	limits                     []AccountLimit
	whitelist_out              []u32 // where money can go to
	whitelist_in               []u32 // where money can come from
	lock_till                  u64   // date in epoch till no money can be transfered, only after
	admin_lock_type            LockType
	admin_lock_till            u64   // date in epoch when admin can unlock (0 means its free), this is unlock for changing this policy
	admin_unlock               []u32 // users who can unlock the admin policy
	admin_unlock_min_signature u8    // nr of signatures from the adminunlock
	clawback_accounts          []u32 // account(s) which can clawback
	clawback_min_signatures    u8
	clawback_from              u64 // from epoch money can be clawed back, 0 is always
	clawback_till              u64 // till which date
}

pub fn (self AccountPolicy) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.policy_id)
	e.add_list_u32(self.admins)
	e.add_u8(self.min_signatures)
	e.add_u32(u32(self.limits.len))
	for limit in self.limits {
		limit.dump(mut e)!
	}
	e.add_list_u32(self.whitelist_out)
	e.add_list_u32(self.whitelist_in)
	e.add_u64(self.lock_till)
	e.add_u8(u8(self.admin_lock_type))
	e.add_u64(self.admin_lock_till)
	e.add_list_u32(self.admin_unlock)
	e.add_u8(self.admin_unlock_min_signature)
	e.add_list_u32(self.clawback_accounts)
	e.add_u8(self.clawback_min_signatures)
	e.add_u64(self.clawback_from)
	e.add_u64(self.clawback_till)
}

fn (mut self AccountPolicy) load(mut e encoder.Decoder) ! {
	self.policy_id = e.get_u32()!
	self.admins = e.get_list_u32()!
	self.min_signatures = e.get_u8()!
	limits_len := e.get_u32()!
	self.limits = []AccountLimit{cap: int(limits_len)}
	for _ in 0 .. limits_len {
		mut limit := AccountLimit{}
		limit.load(mut e)!
		self.limits << limit
	}
	self.whitelist_out = e.get_list_u32()!
	self.whitelist_in = e.get_list_u32()!
	self.lock_till = e.get_u64()!
	self.admin_lock_type = unsafe { LockType(e.get_u8()!) }
	self.admin_lock_till = e.get_u64()!
	self.admin_unlock = e.get_list_u32()!
	self.admin_unlock_min_signature = e.get_u8()!
	self.clawback_accounts = e.get_list_u32()!
	self.clawback_min_signatures = e.get_u8()!
	self.clawback_from = e.get_u64()!
	self.clawback_till = e.get_u64()!
}

pub enum LockType {
	locked_till
	locked
	free
}

pub struct AccountLimit {
pub mut:
	amount   f64
	asset_id u32
	period   AccountLimitPeriodLimit
}

pub fn (self AccountLimit) dump(mut e encoder.Encoder) ! {
	e.add_f64(self.amount)
	e.add_u32(self.asset_id)
	e.add_u8(u8(self.period))
}

fn (mut self AccountLimit) load(mut e encoder.Decoder) ! {
	self.amount = e.get_f64()!
	self.asset_id = e.get_u32()!
	self.period = unsafe { AccountLimitPeriodLimit(e.get_u8()!) }
}

pub enum AccountLimitPeriodLimit {
	daily
	weekly
	monthly
}

pub struct AccountAsset {
	db.Base
pub mut:
	assetid  u32
	balance  f64
	metadata map[string]string
}

pub fn (self AccountAsset) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.assetid)
	e.add_f64(self.balance)
	e.add_map_string(self.metadata)
}

fn (mut self AccountAsset) load(mut e encoder.Decoder) ! {
	self.assetid = e.get_u32()!
	self.balance = e.get_f64()!
	self.metadata = e.get_map_string()!
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
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

pub fn (self Account) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"account": {"owner_id": 1, "location_id": 1, "accountpolicies": [], "assets": [], "assetid": 1, "last_activity": 0, "administrators": []}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"owner_id": 1, "location_id": 1, "accountpolicies": [], "assets": [], "assetid": 1, "last_activity": 0, "administrators": []}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"owner_id": 1, "location_id": 1, "accountpolicies": [], "assets": [], "assetid": 1, "last_activity": 0, "administrators": []}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Account) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.owner_id)
	e.add_u32(self.location_id)
	e.add_u32(u32(self.accountpolicies.len))
	for policy in self.accountpolicies {
		policy.dump(mut e)!
	}
	e.add_u32(u32(self.assets.len))
	for asset in self.assets {
		asset.dump(mut e)!
	}
	e.add_u32(self.assetid)
	e.add_u64(self.last_activity)
	e.add_list_u32(self.administrators)
}

fn (mut self DBAccount) load(mut o Account, mut e encoder.Decoder) ! {
	o.owner_id = e.get_u32()!
	o.location_id = e.get_u32()!
	policies_len := e.get_u32()!
	o.accountpolicies = []AccountPolicy{cap: int(policies_len)}
	for _ in 0 .. policies_len {
		mut policy := AccountPolicy{}
		policy.load(mut e)!
		o.accountpolicies << policy
	}
	assets_len := e.get_u32()!
	o.assets = []AccountAsset{cap: int(assets_len)}
	for _ in 0 .. assets_len {
		mut asset := AccountAsset{}
		asset.load(mut e)!
		o.assets << asset
	}
	o.assetid = e.get_u32()!
	o.last_activity = e.get_u64()!
	o.administrators = e.get_list_u32()!
}

@[params]
pub struct AccountPolicyArg {
pub mut:
	policy_id                  u32
	admins                     []u32
	min_signatures             u8
	limits                     []AccountLimit
	whitelist_out              []u32
	whitelist_in               []u32
	lock_till                  u64
	admin_lock_type            LockType
	admin_lock_till            u64
	admin_unlock               []u32
	admin_unlock_min_signature u8
	clawback_accounts          []u32
	clawback_min_signatures    u8
	clawback_from              u64
	clawback_to                u64
}

pub struct AccountArg {
pub mut:
	name            string
	description     string
	owner_id        u32
	location_id     u32
	accountpolicies []AccountPolicyArg
	assets          []AccountAsset
	assetid         u32
	last_activity   u64
	administrators  []u32
}

pub fn (mut self DBAccount) new(args AccountArg) !Account {
	mut accountpolicies := []AccountPolicy{}
	for policy_arg in args.accountpolicies {
		accountpolicies << AccountPolicy{
			policy_id:                  policy_arg.policy_id
			admins:                     policy_arg.admins
			min_signatures:             policy_arg.min_signatures
			limits:                     policy_arg.limits
			whitelist_out:              policy_arg.whitelist_out
			whitelist_in:               policy_arg.whitelist_in
			lock_till:                  policy_arg.lock_till
			admin_lock_type:            policy_arg.admin_lock_type
			admin_lock_till:            policy_arg.admin_lock_till
			admin_unlock:               policy_arg.admin_unlock
			admin_unlock_min_signature: policy_arg.admin_unlock_min_signature
			clawback_accounts:          policy_arg.clawback_accounts
			clawback_min_signatures:    policy_arg.clawback_min_signatures
			clawback_from:              policy_arg.clawback_from
			clawback_till:              policy_arg.clawback_to
		}
	}

	mut o := Account{
		owner_id:        args.owner_id
		location_id:     args.location_id
		accountpolicies: accountpolicies
		assets:          args.assets
		assetid:         args.assetid
		last_activity:   args.last_activity
		administrators:  args.administrators
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
