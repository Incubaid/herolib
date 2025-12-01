module models_ledger

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

pub fn (self AccountLimit) dump(mut e encoder.Encoder) ! {
	e.add_u64(self.amount)
	e.add_u32(self.asset_id)
	e.add_u8(u8(self.period))
}

fn (mut self AccountLimit) load(mut e encoder.Decoder) ! {
	self.amount = e.get_u64()!
	self.asset_id = e.get_u32()!
	self.period = unsafe { AccountLimitPeriodLimit(e.get_u8()!) }
}

pub fn (self AccountAsset) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.assetid)
	e.add_u64(self.balance)
	e.add_map_string(self.metadata)
}

fn (mut self AccountAsset) load(mut e encoder.Decoder) ! {
	self.assetid = e.get_u32()!
	self.balance = e.get_u64()!
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
			clawback_to:                policy_arg.clawback_to
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
		// Add filter logic based on account properties
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

// Response struct for API
pub struct Response {
pub mut:
	id      int
	jsonrpc string = '2.0'
	result  string
	error   ?ResponseError
}

pub struct ResponseError {
pub mut:
	code    int
	message string
}

pub fn new_response(rpcid int, result string) Response {
	return Response{
		id:     rpcid
		result: result
	}
}

pub fn new_response_true(rpcid int) Response {
	return Response{
		id:     rpcid
		result: 'true'
	}
}

pub fn new_response_false(rpcid int) Response {
	return Response{
		id:     rpcid
		result: 'false'
	}
}

pub fn new_response_int(rpcid int, result int) Response {
	return Response{
		id:     rpcid
		result: result.str()
	}
}

pub fn new_error(rpcid int, code int, message string) Response {
	return Response{
		id:    rpcid
		error: ResponseError{
			code:    code
			message: message
		}
	}
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
				message: 'Method ${method} not found on account'
			)
		}
	}
}
