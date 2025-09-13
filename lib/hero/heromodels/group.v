module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Group represents a collection of users with roles and permissions
@[heap]
pub struct Group {
	db.Base
pub mut:
	members      []GroupMember
	subgroups    []u32 // IDs of child groups
	parent_group u32   // ID of parent group
	is_public    bool
}

pub struct GroupMember {
pub mut:
	user_id   u32
	role      GroupRole
	joined_at i64
}

pub enum GroupRole {
	reader
	writer
	admin
	owner
}

pub fn (self Group) type_name() string {
	return 'group'
}

pub fn (self Group) dump(mut e &encoder.Encoder) ! {
	e.add_u16(u16(self.members.len))
	for member in self.members {
		e.add_u32(member.user_id)
		e.add_u8(u8(member.role))
		e.add_i64(member.joined_at)
	}
	e.add_list_u32(self.subgroups)
	e.add_u32(self.parent_group)
	e.add_bool(self.is_public)
}

fn (mut self DBGroup) load(mut o Group, mut e &encoder.Decoder) ! {
	members_len := e.get_u16()!
	mut members := []GroupMember{}
	for _ in 0 .. members_len {
		user_id := e.get_u32()!
		role := unsafe { GroupRole(e.get_u8()!) }
		joined_at := e.get_i64()!
		
		members << GroupMember{
			user_id:   user_id
			role:      role
			joined_at: joined_at
		}
	}
	o.members = members
	
	o.subgroups = e.get_list_u32()!
	o.parent_group = e.get_u32()!
	o.is_public = e.get_bool()!
}

@[params]
pub struct GroupArg {
pub mut:
	name         string
	description  string
	members      []GroupMember
	subgroups    []u32
	parent_group u32
	is_public    bool
}

pub struct DBGroup {
pub mut:
	db &db.DB @[skip; str: skip]
}

// get new group, not from the DB
pub fn (mut self DBGroup) new(args GroupArg) !Group {
	mut o := Group{
		members:      args.members
		subgroups:    args.subgroups
		parent_group: args.parent_group
		is_public:    args.is_public
	}
	
	// Set base fields
	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()
	
	return o
}

pub fn (mut self DBGroup) set(o Group) !u32 {
	return self.db.set[Group](o)!
}

pub fn (mut self DBGroup) delete(id u32) ! {
	self.db.delete[Group](id)!
}

pub fn (mut self DBGroup) exist(id u32) !bool {
	return self.db.exists[Group](id)!
}

pub fn (mut self DBGroup) get(id u32) !Group {
	mut o, data := self.db.get_data[Group](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBGroup) list() ![]Group {
	return self.db.list[Group]()!.map(self.get(it)!)
}

pub fn (mut self Group) add_member(user_id u32, role GroupRole) {
	mut member := GroupMember{
		user_id:   user_id
		role:      role
		joined_at: ourtime.now().unix()
	}
	self.members << member
}


//CUSTOM FEATURES FOR GROUP