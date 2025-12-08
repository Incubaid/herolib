module ledger

import incubaid.herolib.data.encoder

pub fn (self AccountPolicy) dump(mut e encoder.Encoder) ! {
	e.add_u16(1) // version
	e.add_u32(self.policy_id)
	e.add_list_u32(self.admins)
	e.add_u8(self.min_signatures)
	e.add_u32(u32(self.limits.len))
	for limit in self.limits {
		limit.dump(mut e)!
	}
	e.add_list_u32(self.whitelist_out)
	e.add_list_u32(self.whitelist_in)
	e.add_u32(self.lock_till)
	e.add_u8(u8(self.admin_lock_type))
	e.add_u32(self.admin_lock_till)
	e.add_list_u32(self.admin_unlock)
	e.add_u8(self.admin_unlock_min_signature)
	e.add_list_u32(self.clawback_accounts)
	e.add_u8(self.clawback_min_signatures)
	e.add_u32(self.clawback_from)
	e.add_u32(self.clawback_till)
}

fn (mut self AccountPolicy) load(mut e encoder.Decoder) ! {
	version := e.get_u16()!
	assert version == 1, 'Unsupported AccountPolicyP version: ${version}'
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
	self.lock_till = e.get_u32()!
	self.admin_lock_type = unsafe { LockType(e.get_u8()!) }
	self.admin_lock_till = e.get_u32()!
	self.admin_unlock = e.get_list_u32()!
	self.admin_unlock_min_signature = e.get_u8()!
	self.clawback_accounts = e.get_list_u32()!
	self.clawback_min_signatures = e.get_u8()!
	self.clawback_from = e.get_u32()!
	self.clawback_till = e.get_u32()!
}

pub fn (self AccountLimit) dump(mut e encoder.Encoder) ! {
	e.add_u16(1) // version
	e.add_u64(self.amount)
	e.add_u32(self.asset_id)
	e.add_u8(u8(self.period))
}

fn (mut self AccountLimit) load(mut e encoder.Decoder) ! {
	version := e.get_u16()!
	assert version == 1, 'Unsupported AccountLimitP version: ${version}'
	self.amount = e.get_u32()!
	self.asset_id = e.get_u32()!
	self.period = unsafe { AccountLimitPeriodLimit(e.get_u8()!) }
}

pub fn (self AccountAsset) dump(mut e encoder.Encoder) ! {
	e.add_u16(1) // version
	e.add_u32(self.assetid)
	e.add_u64(self.balance)
	e.add_map_string(self.metadata)
}

fn (mut self AccountAsset) load(mut e encoder.Decoder) ! {
	version := e.get_u16()!
	assert version == 1, 'Unsupported AccountAssetP version: ${version}'
	self.assetid = e.get_u32()!
	self.balance = e.get_u32()!
	self.metadata = e.get_map_string()!
}

pub fn (self Account) dump(mut e encoder.Encoder) ! {
	e.add_u16(1) // version
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
	e.add_u32(self.last_activity)
	e.add_list_u32(self.administrators)
}

fn (mut self DBAccount) load(mut o Account, mut e encoder.Decoder) ! {
	version := e.get_u16()!
	assert version == 1, 'Unsupported Account version: ${version}'
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
	o.last_activity = e.get_u32()!
	o.administrators = e.get_list_u32()!
}
