module ledger

import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db
import json


// Account represents an account in the financial system
@[heap]
pub struct Account {
	db.Base
pub mut:
	owner_id        u32 // link to user, o is not defined
	location_id     u32 // link to location, 0 is none
	accountpolicies []AccountPolicy
	assets          []AccountAsset
	assetid         u32
	last_activity   u64
	administrators  []u32
	status		 	AccountStatus
}

// AccountStatus represents the status of an account
pub enum AccountStatus {
	active
	inactive
	suspended
	archived
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
	lock_till                  u32   // date in epoch till no money can be transfered, only after
	admin_lock_type            LockType
	admin_lock_till            u32   // date in epoch when admin can unlock (0 means its free), this is unlock for changing this policy
	admin_unlock               []u32 // users who can unlock the admin policy
	admin_unlock_min_signature u8    // nr of signatures from the adminunlock
	clawback_accounts          []u32 // account(s) which can clawback
	clawback_min_signatures    u8
	clawback_from              u32 // from epoch money can be clawed back, 0 is always
	clawback_till              u32 // till which date
}


pub enum LockType {
	locked_till
	locked
	free
}

pub struct AccountLimit {
pub mut:
	amount   u64 //in smallest unit
	asset_id u32
	period   AccountLimitPeriodLimit
}


pub enum AccountLimitPeriodLimit {
	daily
	weekly
	monthly
}

pub struct AccountAsset {
pub mut:
	assetid  u32
	balance  u64
	metadata map[string]string
}
