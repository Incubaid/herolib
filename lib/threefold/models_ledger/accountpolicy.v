module models_ledger

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// AccountPolicy represents a set of rules for an account
@[heap]
pub struct AccountPolicy {
	db.Base
pub mut:
	policy_id          u32 @[index]
	min_signatures     u32
	max_tx_amount      f64
	daily_limit        f64
	whitelist          []u32
	blacklist          []u32
	require_2fa        bool
	lockout_period     u64
	is_multisig        bool
}

pub struct DBAccountPolicy {
pub mut:
	db &db.DB @[skip; str: skip]
}


pub fn (self AccountPolicy) type_name() string {
	return 'accountpolicy'
}

pub fn (self AccountPolicy) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update an account policy. Returns the ID of the policy.'
		}
		'get' {
			return 'Retrieve an account policy by ID. Returns the policy object.'
		}
		'delete' {
			return 'Delete an account policy by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if an account policy exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all account policies. Returns an array of policy objects.'
		}
		else {
			return 'Account policy management operations'
		}
	}
}

pub fn (self AccountPolicy) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"accountpolicy": {"policy_id": 1, "min_signatures": 2, "max_tx_amount": 10000.0, "daily_limit": 50000.0, "is_multisig": true}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"policy_id": 1, "min_signatures": 2, "is_multisig": true}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"policy_id": 1, "min_signatures": 2, "is_multisig": true}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self AccountPolicy) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.policy_id)
	e.add_u32(self.min_signatures)
	e.add_f64(self.max_tx_amount)
	e.add_f64(self.daily_limit)
	e.add_list_u32(self.whitelist)
	e.add_list_u32(self.blacklist)
	e.add_bool(self.require_2fa)
	e.add_u64(self.lockout_period)
	e.add_bool(self.is_multisig)
}

fn (mut self DBAccountPolicy) load(mut o AccountPolicy, mut e encoder.Decoder) ! {
	o.policy_id = e.get_u32()!
	o.min_signatures = e.get_u32()!
	o.max_tx_amount = e.get_f64()!
	o.daily_limit = e.get_f64()!
	o.whitelist = e.get_list_u32()!
	o.blacklist = e.get_list_u32()!
	o.require_2fa = e.get_bool()!
	o.lockout_period = e.get_u64()!
	o.is_multisig = e.get_bool()!
}

@[params]
pub struct AccountPolicyArg {
pub mut:
	name           string
	description    string
	policy_id      u32
	min_signatures u32
	max_tx_amount  f64
	daily_limit    f64
	whitelist      []u32
	blacklist      []u32
	require_2fa    bool
	lockout_period u64
	is_multisig    bool
}

pub fn (mut self DBAccountPolicy) new(args AccountPolicyArg) !AccountPolicy {
	mut o := AccountPolicy{
		policy_id:      args.policy_id
		min_signatures: args.min_signatures
		max_tx_amount:  args.max_tx_amount
		daily_limit:    args.daily_limit
		whitelist:      args.whitelist
		blacklist:      args.blacklist
		require_2fa:    args.require_2fa
		lockout_period: args.lockout_period
		is_multisig:    args.is_multisig
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBAccountPolicy) set(o AccountPolicy) !AccountPolicy {
	return self.db.set[AccountPolicy](o)!
}_
 
pub fn (mut self DBAccountPolicy) delete(id u32) ! {
	self.db.delete[AccountPolicy](id)!
}

pub fn (mut self DBAccountPolicy) exist(id u32) !bool {
	return self.db.exists[AccountPolicy](id)!
}

pub fn (mut self DBAccountPolicy) get(id u32) !AccountPolicy {
	mut o, data := self.db.get_data[AccountPolicy](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBAccountPolicy) list() ![]AccountPolicy {
	return self.db.list[AccountPolicy]()!.map(self.get(it)!)
}