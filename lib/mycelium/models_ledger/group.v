// lib/threefold/models_ledger/group.v
module models_ledger

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db

// Group represents a collection of users with shared permissions and access.
@[heap]
pub struct Group {
	db.Base
pub mut:
	group_name     string @[index; required] // The unique name of the group.
	dnsrecords     []u32       // A list of DNS record IDs associated with this group.
	administrators []u32       // A list of user IDs that are administrators for this group.
	min_signatures u32         // The minimum number of signatures required for administrative actions.
	config         GroupConfig // The configuration settings for the group.
	status         GroupStatus // The current status of the group (e.g., active, inactive).
	visibility     Visibility  // The visibility level of the group (e.g., public, private).
	created        u64         // The timestamp when the group was created.
	updated        u64         // The timestamp when the group was last updated.
}

// GroupStatus defines the lifecycle of a group
pub enum GroupStatus {
	active
	inactive
	suspended
	archived
}

// Visibility controls who can discover or view the group
pub enum Visibility {
	public
	private
	unlisted
}

// GroupConfig defines the settings and rules for a group.
pub struct GroupConfig {
pub mut:
	max_members    u32  // The maximum number of members allowed in the group.
	allow_guests   bool // Whether non-members are allowed to view the group's content.
	auto_approve   bool // Whether new members are automatically approved or require manual approval.
	require_invite bool // Whether a user must be invited to join the group.
}

pub struct DBGroup {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Group) type_name() string {
	return 'group'
}

pub fn (self Group) description(methodname string) string {
	return match methodname {
		'set' { 'Create or update a group. Returns the ID of the group.' }
		'get' { 'Retrieve a group by its unique ID.' }
		'delete' { 'Deletes a group by its unique ID.' }
		'exist' { 'Checks if a group with the given ID exists.' }
		'find' { 'Finds groups based on a filter expression.' }
		'count' { 'Counts the number of groups that match a filter expression.' }
		'list' { 'Lists all groups, optionally filtered and sorted.' }
		else { 'A group represents a collection of users with shared permissions and access.' }
	}
}

pub fn (self Group) example(methodname string) (string, string) {
	return match methodname {
		'set' { '{"group": {"id": 1, "name": "Development Team", "description": "Core development group", "status": "active", "visibility": "private"}}', '1' }
		'get' { '{"id": 1}', '{"id": 1, "name": "Development Team", "description": "Core development group", "status": "active", "visibility": "private"}' }
		'delete' { '{"id": 1}', 'true' }
		'exist' { '{"id": 1}', 'true' }
		'find' { '{"filter": "name=\'Development Team\'"}', '[{"id": 1, "name": "Development Team", "description": "Core development group", "status": "active", "visibility": "private"}]' }
		'count' { '{"filter": "name=\'Development Team\'"}', '1' }
		'list' { '{}', '[{"id": 1, "name": "Development Team", "description": "Core development group", "status": "active", "visibility": "private"}]' }
		else { '{}', '{}' }
	}
}

pub fn (self Group) dump(mut e encoder.Encoder) ! {
	e.add_string(self.group_name)
	e.add_list_u32(self.dnsrecords)
	e.add_list_u32(self.administrators)
	e.add_u32(self.min_signatures)
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
	o.min_signatures = e.get_u32()!
	// GroupConfig
	o.config = GroupConfig{
		max_members:    e.get_u32()!
		allow_guests:   e.get_bool()!
		auto_approve:   e.get_bool()!
		require_invite: e.get_bool()!
	}

	o.status = unsafe { GroupStatus(e.get_int()!) }
	o.visibility = unsafe { Visibility(e.get_int()!) }
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
	min_signatures u32
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
		min_signatures: args.min_signatures
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
