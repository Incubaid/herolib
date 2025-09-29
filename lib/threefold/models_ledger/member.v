module models_ledger

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// MemberRole defines the role of a user within a group
pub enum MemberRole {
	member
	moderator
	admin
	owner
}

// MemberStatus defines the status of a membership
pub enum MemberStatus {
	pending
	active
	suspended
	archived
}

// Member represents the association of a user to a group
@[heap]
pub struct Member {
	db.Base
pub mut:
	group_id      u32 @[index]
	user_id       u32 @[index]
	role          MemberRole
	status        MemberStatus
	join_date     u64
	last_activity u64
}

pub struct DBMember {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Member) type_name() string {
	return 'member'
}

pub fn (self Member) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a group member. Returns the ID of the member.'
		}
		'get' {
			return 'Retrieve a member by ID. Returns the member object.'
		}
		'delete' {
			return 'Delete a member by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a member exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all members. Returns an array of member objects.'
		}
		else {
			return 'Member management operations'
		}
	}
}

pub fn (self Member) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"member": {"group_id": 1, "user_id": 1, "role": "admin", "status": "active"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"group_id": 1, "user_id": 1, "role": "admin", "status": "active"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"group_id": 1, "user_id": 1, "role": "admin", "status": "active"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Member) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.group_id)
	e.add_u32(self.user_id)
	e.add_u8(u8(self.role))
	e.add_u8(u8(self.status))
	e.add_u64(self.join_date)
	e.add_u64(self.last_activity)
}

fn (mut self DBMember) load(mut o Member, mut e encoder.Decoder) ! {
	o.group_id = e.get_u32()!
	o.user_id = e.get_u32()!
	o.role = unsafe { MemberRole(e.get_u8()!) }
	o.status = unsafe { MemberStatus(e.get_u8()!) }
	o.join_date = e.get_u64()!
	o.last_activity = e.get_u64()!
}

@[params]
pub struct MemberArg {
pub mut:
	name        string
	description string
	group_id    u32
	user_id     u32
	role        MemberRole   = .member
	status      MemberStatus = .pending
}

pub fn (mut self DBMember) new(args MemberArg) !Member {
	now := ourtime.now().unix()
	mut o := Member{
		group_id:      args.group_id
		user_id:       args.user_id
		role:          args.role
		status:        args.status
		join_date:     u64(now)
		last_activity: u64(now)
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = now

	return o
}

pub fn (mut self DBMember) set(o Member) !Member {
	return self.db.set[Member](o)!
}

pub fn (mut self DBMember) delete(id u32) ! {
	self.db.delete[Member](id)!
}

pub fn (mut self DBMember) exist(id u32) !bool {
	return self.db.exists[Member](id)!
}

pub fn (mut self DBMember) get(id u32) !Member {
	mut o, data := self.db.get_data[Member](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBMember) list() ![]Member {
	return self.db.list[Member]()!.map(self.get(it)!)
}
