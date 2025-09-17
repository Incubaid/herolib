// lib/threefold/models_ledger/usergroupmembership.v
module models_ledger

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// UserGroupMembership represents the membership relationship between users and groups
@[heap]
pub struct UserGroupMembership {
	db.Base
pub mut:
	user_id   u32 @[index]
	group_ids []u32
}

pub struct DBUserGroupMembership {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self UserGroupMembership) type_name() string {
	return 'usergroupmembership'
}

pub fn (self UserGroupMembership) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a user group membership. Returns the ID of the membership.'
		}
		'get' {
			return 'Retrieve a user group membership by ID. Returns the membership object.'
		}
		'delete' {
			return 'Delete a user group membership by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a user group membership exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all user group memberships. Returns an array of membership objects.'
		}
		else {
			return 'User group membership management operations'
		}
	}
}

pub fn (self UserGroupMembership) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"usergroupmembership": {"user_id": 1, "group_ids": [1, 2, 3]}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"user_id": 1, "group_ids": [1, 2, 3]}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"user_id": 1, "group_ids": [1, 2, 3]}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self UserGroupMembership) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.user_id)
	e.add_list_u32(self.group_ids)
}

fn (mut self DBUserGroupMembership) load(mut o UserGroupMembership, mut e encoder.Decoder) ! {
	o.user_id = e.get_u32()!
	o.group_ids = e.get_list_u32()!
}

@[params]
pub struct UserGroupMembershipArg {
pub mut:
	name        string
	description string
	user_id     u32
	group_ids   []u32
}

pub fn (mut self DBUserGroupMembership) new(args UserGroupMembershipArg) !UserGroupMembership {
	mut o := UserGroupMembership{
		user_id:   args.user_id
		group_ids: args.group_ids
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBUserGroupMembership) set(o UserGroupMembership) !UserGroupMembership {
	return self.db.set[UserGroupMembership](o)!
}

pub fn (mut self DBUserGroupMembership) delete(id u32) ! {
	self.db.delete[UserGroupMembership](id)!
}

pub fn (mut self DBUserGroupMembership) exist(id u32) !bool {
	return self.db.exists[UserGroupMembership](id)!
}

pub fn (mut self DBUserGroupMembership) get(id u32) !UserGroupMembership {
	mut o, data := self.db.get_data[UserGroupMembership](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBUserGroupMembership) list() ![]UserGroupMembership {
	return self.db.list[UserGroupMembership]()!.map(self.get(it)!)
}