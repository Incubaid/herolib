module ledger

import incubaid.herolib.hero.db
import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_true }
import json

pub struct DBAccount {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Account) type_name() string {
	return 'Account'
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
	lock_till                  u32
	admin_lock_type            LockType
	admin_lock_till            u32
	admin_unlock               []u32
	admin_unlock_min_signature u8
	clawback_accounts          []u32
	clawback_min_signatures    u8
	clawback_from              u32
	clawback_till              u32
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
	last_activity   u32 // timestamp
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
			clawback_till:              policy_arg.clawback_till
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
	o.updated_at = u32(ourtime.now().unix())

	return o
}

pub fn (mut self DBAccount) set(o Account) !Account {
	return self.db.set[Account](o)!
}

pub fn (mut self DBAccount) delete(id u32) !bool {
	if !self.db.exists[Account](id)! {
		return false
	}
	self.db.delete[Account](id)!
	return true
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

@[params]
pub struct AccountListArg {
pub mut:
	filter string
	status int = -1
	limit  int = 20
	offset int = 0
}

pub fn (mut self DBAccount) list(args AccountListArg) ![]Account {
	mut all_accounts := self.db.list[Account]()!.map(self.get(it)!)
	mut filtered_accounts := []Account{}

	for account in all_accounts {
		// Add filter logic based on Account properties
		if args.filter != '' && !account.name.contains(args.filter)
			&& !account.description.contains(args.filter) {
			continue
		}

		// We could add more filters based on status if the Account struct has a status field

		filtered_accounts << account
	}

	// Apply pagination
	mut start := args.offset
	if start >= filtered_accounts.len {
		start = 0
	}

	mut limit := args.limit
	if limit > 100 {
		limit = 100
	}

	if start + limit > filtered_accounts.len {
		limit = filtered_accounts.len - start
	}

	if limit <= 0 {
		return []Account{}
	}

	return if filtered_accounts.len > 0 {
		filtered_accounts[start..start + limit]
	} else {
		[]Account{}
	}
}

pub fn (mut self DBAccount) list_all() ![]Account {
	return self.db.list[Account]()!.map(self.get(it)!)
}

pub struct UserRef {
pub mut:
	id u32
}

pub fn account_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.account.get(id)!
			return new_response(rpcid, json.encode_pretty(res))
		}
		'set' {
			mut args := db.decode_generic[AccountArg](params)!
			mut o := f.account.new(args)!
			if args.id != 0 {
				o.id = args.id
			}
			o = f.account.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			success := f.account.delete(id)!
			if success {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.account.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			args := db.decode_generic_or_default[AccountListArg](params, AccountListArg{})!
			result := f.account.list(args)!
			return new_response(rpcid, json.encode_pretty(result))
		}
		else {
			return new_error(
				rpcid:   rpcid
				code:    32601
				message: 'Method ${method} not found on Account'
			)
		}
	}
}
