#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!

// Create a new group with members
mut o := mydb.group.new(
	name:         'Development Team'
	description:  'Group for software developers'
	is_public:    false
	members:      [
		heromodels.GroupMember{
			user_id:   1
			role:      heromodels.GroupRole.admin
			joined_at: 0 // Will be set when adding to group
		},
		heromodels.GroupMember{
			user_id:   2
			role:      heromodels.GroupRole.writer
			joined_at: 0 // Will be set when adding to group
		},
	]
	subgroups:    []
	parent_group: 0
)!

// Add tags if needed
o.tags = mydb.group.db.tags_get(['team', 'development'])!

// Save to database
mydb.group.set(mut o)!
println('Created Group ID: ${o.id}')

// Check if the group exists
mut exists := mydb.group.exist(o.id)!
println('Group exists: ${exists}')

// Retrieve from database
mut o2 := mydb.group.get(o.id)!
println('Retrieved Group object: ${o2}')

// List all groups
mut objects := mydb.group.list()!
println('All groups count: ${objects.len}')
