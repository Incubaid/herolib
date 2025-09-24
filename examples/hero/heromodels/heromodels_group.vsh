#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!

// Create a new group
mut o := mydb.group.new(
	name:         'Development Team'
	description:  'Group for software developers'
	is_public:    false
	members:      []
	subgroups:    []
	parent_group: 0
)!

// Add tags if needed
o.tags = mydb.group.db.tags_get(['team', 'development'])!

// Save to database
oid := mydb.group.set(o)!
println('Created Group ID: ${oid}')

// Check if the group exists
mut exists := mydb.group.exist(oid)!
println('Group exists: ${exists}')

// Retrieve from database
mut o2 := mydb.group.get(oid)!
println('Retrieved Group object: ${o2}')

// List all groups
mut objects := mydb.group.list()!
println('All groups: ${objects}')

// Delete the group
mydb.group.delete(oid)!
println('Deleted group with ID: ${oid}')

// Check if the group still exists
exists = mydb.group.exist(oid)!
println('Group exists after deletion: ${exists}')
