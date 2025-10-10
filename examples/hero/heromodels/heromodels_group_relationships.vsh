#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!

// Create a parent group
mut parent_group := mydb.group.new(
	name:         'Company'
	description:  'Main company group'
	is_public:    true
	members:      []
	subgroups:    []
	parent_group: 0
)!

mydb.group.set(mut parent_group)!
println('Created Parent Group ID: ${parent_group.id}')

// Create a subgroup
mut subgroup := mydb.group.new(
	name:         'Development Team'
	description:  'Subgroup for developers'
	is_public:    false
	members:      []
	subgroups:    []
	parent_group: parent_group.id
)!

mydb.group.set(mut subgroup)!
println('Created Subgroup ID: ${subgroup.id}')

// Update the parent group to include the subgroup
mut updated_parent := mydb.group.get(parent_group.id)!
updated_parent.subgroups = [subgroup.id]
mydb.group.set(mut updated_parent)!

// Retrieve both groups to verify relationships
mut parent_from_db := mydb.group.get(parent_group.id)!
mut sub_from_db := mydb.group.get(subgroup.id)!

println('Parent Group: ${parent_from_db}')
println('Subgroup: ${sub_from_db}')

// Verify the relationships
println('Parent group has ${parent_from_db.subgroups.len} subgroups')
println('Subgroup has parent group ID: ${sub_from_db.parent_group}')
