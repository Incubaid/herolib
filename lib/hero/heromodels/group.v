module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_ok, new_response_true, new_response_int }
import freeflowuniverse.herolib.hero.user { UserRef }
import json

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

// return example rpc call and result for each methodname
pub fn (self Group) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a group. Returns the ID of the group.'
		}
		'get' {
			return 'Retrieve a group by ID. Returns the group object.'
		}
		'delete' {
			return 'Delete a group by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a group exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all groups. Returns an array of group objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self Group) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"group": {"name": "Admins", "description": "Administrators group", "members": [{"user_id": 1, "role": "admin", "joined_at": 1678886400}], "subgroups": [], "parent_group": 0, "is_public": false}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "Admins", "description": "Administrators group", "members": [{"user_id": 1, "role": "admin", "joined_at": 1678886400}], "subgroups": [], "parent_group": 0, "is_public": false}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "Admins", "description": "Administrators group", "members": [{"user_id": 1, "role": "admin", "joined_at": 1678886400}], "subgroups": [], "parent_group": 0, "is_public": false}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Group) dump(mut e encoder.Encoder) ! {
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

fn (mut self DBGroup) load(mut o Group, mut e encoder.Decoder) ! {
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

pub fn (mut self DBGroup) set(o Group) !Group {
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

// CUSTOM FEATURES FOR GROUP


pub fn group_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.group.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut o := db.decode_generic[Group](params)!
			o = f.group.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			f.group.delete(id)!
			return new_response_ok(rpcid)
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.group.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			req := jsonrpc.new_request(method, '')
			res := f.group.list()!
			return new_response(req.id, json.encode(res))
		}
		else {
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on group'
			)
		}
	}
}