// lib/threefold/models_ledger/group.v
module models_ledger

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// GroupStatus defines the lifecycle of a group
pub enum GroupStatus {
	active
	inactive
	suspended
	archived
}

// Visibility controls who can discover or view the group
pub enum Visibility {
	public_
	private_
	unlisted
}

// GroupConfig holds rules that govern group membership and behavior
pub struct GroupConfig {
pub mut:
	max_members    u32
	allow_guests   bool
	auto_approve   bool
	require_invite bool
}

// Group represents a collaborative or access-controlled unit within the system
@[heap]
pub struct Group {
	db.Base
pub mut:
	group_name     string @[index]
	dnsrecords     []u32
	administrators []u32
	config         GroupConfig
	status         GroupStatus
	visibility     Visibility
	created        u64
	updated        u64
}

pub struct DBGroup {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Group) type_name() string {
	return 'group'
}

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
			return 'Group management operations'
		}
	}
}

pub fn (self Group) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"group": {"name": "Development Team", "description": "Core development group", "status": "active", "visibility": "private"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "Development Team", "description": "Core development group", "status": "active", "visibility": "private"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "Development Team", "description": "Core development group", "status": "active", "visibility": "private"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Group) dump(mut e encoder.Encoder) ! {
	e.add_string(self.group_name)
	e.add_list_u32(self.dnsrecords)
	e.add_list_u32(self.administrators)
	
	// GroupConfig
	e.add_u32(self.config.max_members)
	e.add_bool(self.config.allow_guests)
	e.add_bool(self.config.auto_approve)
	e.add_bool(self.config.require_invite)
	
	e.add_int(int(self.status))
	e.add_int(int(self.visibility))
	e.add_u64(self.created)
	e.add_u64(self.updated)
}

fn (mut self DBGroup) load(mut o Group, mut e encoder.Decoder) ! {
	o.group_name = e.get_string()!
	o.dnsrecords = e.get_list_u32()!
	o.administrators = e.get_list_u32()!
	
	// GroupConfig
	o.config = GroupConfig{
		max_members: e.get_u32()!
		allow_guests: e.get_bool()!
		auto_approve: e.get_bool()!
		require_invite: e.get_bool()!
	}
	
	o.status = GroupStatus(e.get_int()!)
	o.visibility = Visibility(e.get_int()!)
	o.created = e.get_u64()!
	o.updated = e.get_u64()!
}

@[params]
pub struct GroupArg {
pub mut:
	name           string
	description    string
	group_name     string
	dnsrecords     []u32
	administrators []u32
	config         GroupConfig
	status         GroupStatus
	visibility     Visibility
	created        u64
	updated        u64
}

pub fn (mut self DBGroup) new(args GroupArg) !Group {
	mut o := Group{
		group_name:     args.group_name
		dnsrecords:     args.dnsrecords
		administrators: args.administrators
		config:         args.config
		status:         args.status
		visibility:     args.visibility
		created:        args.created
		updated:        args.updated
	}

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