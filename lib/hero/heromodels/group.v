module heromodels

import time
import crypto.blake3
import json

// Group represents a collection of users with roles and permissions
@[heap]
pub struct Group {
pub mut:
	id           string // blake192 hash
	name         string
	description  string
	members      []GroupMember
	subgroups    []string // IDs of child groups
	parent_group string   // ID of parent group
	created_at   i64
	updated_at   i64
	is_public    bool
	tags         []string
}

pub struct GroupMember {
pub mut:
	user_id   string
	role      GroupRole
	joined_at i64
}

pub enum GroupRole {
	reader
	writer
	admin
	owner
}

pub fn (mut g Group) calculate_id() {
	content := json.encode(GroupContent{
		name:         g.name
		description:  g.description
		members:      g.members
		subgroups:    g.subgroups
		parent_group: g.parent_group
		is_public:    g.is_public
		tags:         g.tags
	})
	hash := blake3.sum256(content.bytes())
	g.id = hash.hex()[..48]
}

struct GroupContent {
	name         string
	description  string
	members      []GroupMember
	subgroups    []string
	parent_group string
	is_public    bool
	tags         []string
}

pub fn new_group(name string, description string) Group {
	mut group := Group{
		name:        name
		description: description
		created_at:  time.now().unix()
		updated_at:  time.now().unix()
		is_public:   false
	}
	group.calculate_id()
	return group
}

pub fn (mut g Group) add_member(user_id string, role GroupRole) {
	g.members << GroupMember{
		user_id:   user_id
		role:      role
		joined_at: time.now().unix()
	}
	g.updated_at = time.now().unix()
	g.calculate_id()
}
