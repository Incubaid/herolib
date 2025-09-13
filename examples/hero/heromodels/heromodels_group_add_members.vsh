#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!

// Create a new group without members
mut o := mydb.group.new(
	name: 'Marketing Team'
	description: 'Group for marketing professionals'
	is_public: true
	members: []
	subgroups: []
	parent_group: 0
)!

// Add members to the group
o.add_member(1, heromodels.GroupRole.admin)
o.add_member(2, heromodels.GroupRole.writer)
o.add_member(3, heromodels.GroupRole.reader)

// Add tags if needed
o.tags = mydb.group.db.tags_get(['team', 'marketing'])!

// Save to database
oid := mydb.group.set(o)!
println('Created Group ID: ${oid}')

// Retrieve from database
mut o2 := mydb.group.get(oid)!
println('Retrieved Group object: ${o2}')

// Check the number of members
println('Group members count: ${o2.members.len}')
