#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module heromodels

import freeflowuniverse.herolib.hero.heromodels { GroupMember, GroupRole }
import freeflowuniverse.herolib.data.ourtime

// Test Group model CRUD operations
fn test_group_new() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test creating a new group with all fields
	now := ourtime.now().unix()
	mut group := mydb.group.new(
		name:         'Development Team'
		description:  'Software development team for the main project'
		members:      [
			GroupMember{
				user_id:   1
				role:      .owner
				joined_at: now
			},
			GroupMember{
				user_id:   2
				role:      .admin
				joined_at: now
			},
			GroupMember{
				user_id:   3
				role:      .writer
				joined_at: now
			},
		]
		subgroups:    [u32(10), 20, 30]
		parent_group: 0
		is_public:    false
	) or { panic('Failed to create group: ${err}') }

	// Verify the group was created with correct values
	assert group.name == 'Development Team'
	assert group.description == 'Software development team for the main project'
	assert group.members.len == 3
	assert group.members[0].user_id == 1
	assert group.members[0].role == .owner
	assert group.members[1].user_id == 2
	assert group.members[1].role == .admin
	assert group.members[2].user_id == 3
	assert group.members[2].role == .writer
	assert group.subgroups.len == 3
	assert group.subgroups[0] == 10
	assert group.parent_group == 0
	assert group.is_public == false
	assert group.id == 0 // Should be 0 before saving
	assert group.updated_at > 0 // Should have timestamp
}

fn test_group_set_and_get() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a group
	now := ourtime.now().unix()
	mut group := mydb.group.new(
		name:         'Marketing Team'
		description:  'Marketing and communications team'
		members:      [
			GroupMember{
				user_id:   100
				role:      .owner
				joined_at: now - 86400 // 1 day ago
			},
			GroupMember{
				user_id:   101
				role:      .writer
				joined_at: now
			},
		]
		subgroups:    []u32{}
		parent_group: 5
		is_public:    true
	) or { panic('Failed to create group: ${err}') }

	// Save the group
	group = mydb.group.set(group) or { panic('Failed to save group: ${err}') }

	// Verify ID was assigned
	assert group.id > 0
	original_id := group.id

	// Retrieve the group
	retrieved_group := mydb.group.get(group.id) or { panic('Failed to get group: ${err}') }

	// Verify all fields match
	assert retrieved_group.id == original_id
	assert retrieved_group.name == 'Marketing Team'
	assert retrieved_group.description == 'Marketing and communications team'
	assert retrieved_group.members.len == 2
	assert retrieved_group.members[0].user_id == 100
	assert retrieved_group.members[0].role == .owner
	assert retrieved_group.members[1].user_id == 101
	assert retrieved_group.members[1].role == .writer
	assert retrieved_group.subgroups.len == 0
	assert retrieved_group.parent_group == 5
	assert retrieved_group.is_public == true
	assert retrieved_group.created_at > 0
	assert retrieved_group.updated_at > 0
}

fn test_group_roles() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test all group roles
	roles := [GroupRole.reader, .writer, .admin, .owner]
	now := ourtime.now().unix()

	mut members := []GroupMember{}
	for i, role in roles {
		members << GroupMember{
			user_id:   u32(i + 1)
			role:      role
			joined_at: now + i64(i * 3600) // Different join times
		}
	}

	mut group := mydb.group.new(
		name:         'Role Test Group'
		description:  'Testing all group roles'
		members:      members
		subgroups:    []u32{}
		parent_group: 0
		is_public:    false
	) or { panic('Failed to create group: ${err}') }

	group = mydb.group.set(group) or { panic('Failed to save group: ${err}') }

	retrieved_group := mydb.group.get(group.id) or { panic('Failed to get group: ${err}') }

	// Verify all roles are preserved
	assert retrieved_group.members.len == 4
	assert retrieved_group.members[0].role == .reader
	assert retrieved_group.members[1].role == .writer
	assert retrieved_group.members[2].role == .admin
	assert retrieved_group.members[3].role == .owner

	// Verify join times are preserved
	for i, member in retrieved_group.members {
		assert member.joined_at == now + i64(i * 3600)
	}
}

fn test_group_hierarchy() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create parent group
	mut parent_group := mydb.group.new(
		name:         'Engineering'
		description:  'Main engineering group'
		members:      [
			GroupMember{
				user_id:   1
				role:      .owner
				joined_at: ourtime.now().unix()
			},
		]
		subgroups:    []u32{}
		parent_group: 0
		is_public:    false
	) or { panic('Failed to create parent group: ${err}') }

	parent_group = mydb.group.set(parent_group) or { panic('Failed to save parent group: ${err}') }
	parent_id := parent_group.id

	// Create child groups
	mut frontend_group := mydb.group.new(
		name:         'Frontend Team'
		description:  'Frontend development team'
		members:      [
			GroupMember{
				user_id:   10
				role:      .admin
				joined_at: ourtime.now().unix()
			},
		]
		subgroups:    []u32{}
		parent_group: parent_id
		is_public:    false
	) or { panic('Failed to create frontend group: ${err}') }

	mut backend_group := mydb.group.new(
		name:         'Backend Team'
		description:  'Backend development team'
		members:      [
			GroupMember{
				user_id:   20
				role:      .admin
				joined_at: ourtime.now().unix()
			},
		]
		subgroups:    []u32{}
		parent_group: parent_id
		is_public:    false
	) or { panic('Failed to create backend group: ${err}') }

	frontend_group = mydb.group.set(frontend_group) or { panic('Failed to save frontend group: ${err}') }
	backend_group = mydb.group.set(backend_group) or { panic('Failed to save backend group: ${err}') }

	// Update parent group with subgroups
	parent_group.subgroups = [frontend_group.id, backend_group.id]
	parent_group = mydb.group.set(parent_group) or { panic('Failed to update parent group: ${err}') }

	// Verify hierarchy
	retrieved_parent := mydb.group.get(parent_id) or { panic('Failed to get parent group: ${err}') }
	retrieved_frontend := mydb.group.get(frontend_group.id) or {
		panic('Failed to get frontend group: ${err}')
	}
	retrieved_backend := mydb.group.get(backend_group.id) or {
		panic('Failed to get backend group: ${err}')
	}

	assert retrieved_parent.subgroups.len == 2
	assert retrieved_parent.subgroups.contains(frontend_group.id)
	assert retrieved_parent.subgroups.contains(backend_group.id)
	assert retrieved_frontend.parent_group == parent_id
	assert retrieved_backend.parent_group == parent_id
}

fn test_group_update() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save a group
	now := ourtime.now().unix()
	mut group := mydb.group.new(
		name:         'Original Group'
		description:  'Original description'
		members:      [
			GroupMember{
				user_id:   1
				role:      .reader
				joined_at: now
			},
		]
		subgroups:    []u32{}
		parent_group: 0
		is_public:    false
	) or { panic('Failed to create group: ${err}') }

	group = mydb.group.set(group) or { panic('Failed to save group: ${err}') }
	original_id := group.id
	original_created_at := group.created_at
	original_updated_at := group.updated_at

	// Update the group
	group.name = 'Updated Group'
	group.description = 'Updated description'
	group.members = [
		GroupMember{
			user_id:   1
			role:      .admin
			joined_at: now
		},
		GroupMember{
			user_id:   2
			role:      .writer
			joined_at: now + 3600
		},
	]
	group.subgroups = [u32(100), 200]
	group.parent_group = 50
	group.is_public = true

	group = mydb.group.set(group) or { panic('Failed to update group: ${err}') }

	// Verify ID remains the same and updated_at is set
	assert group.id == original_id
	assert group.created_at == original_created_at
	assert group.updated_at >= original_updated_at

	// Retrieve and verify updates
	updated_group := mydb.group.get(group.id) or { panic('Failed to get updated group: ${err}') }
	assert updated_group.name == 'Updated Group'
	assert updated_group.description == 'Updated description'
	assert updated_group.members.len == 2
	assert updated_group.members[0].role == .admin
	assert updated_group.members[1].role == .writer
	assert updated_group.subgroups.len == 2
	assert updated_group.subgroups[0] == 100
	assert updated_group.parent_group == 50
	assert updated_group.is_public == true
}

fn test_group_exist() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test non-existent group with a very high ID that shouldn't exist
	exists := mydb.group.exist(999999) or { panic('Failed to check existence: ${err}') }
	assert exists == false

	// Create and save a group
	mut group := mydb.group.new(
		name:         'Existence Test'
		description:  'Testing existence'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	) or { panic('Failed to create group: ${err}') }

	group = mydb.group.set(group) or { panic('Failed to save group: ${err}') }

	// Test existing group
	exists_after_save := mydb.group.exist(group.id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_after_save == true
}

fn test_group_delete() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save a group
	mut group := mydb.group.new(
		name:         'To Be Deleted'
		description:  'This group will be deleted'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    false
	) or { panic('Failed to create group: ${err}') }

	group = mydb.group.set(group) or { panic('Failed to save group: ${err}') }
	group_id := group.id

	// Verify it exists
	exists_before := mydb.group.exist(group_id) or { panic('Failed to check existence: ${err}') }
	assert exists_before == true

	// Delete the group
	mydb.group.delete(group_id) or { panic('Failed to delete group: ${err}') }

	// Verify it no longer exists
	exists_after := mydb.group.exist(group_id) or { panic('Failed to check existence: ${err}') }
	assert exists_after == false

	// Verify get fails
	if _ := mydb.group.get(group_id) {
		panic('Should not be able to get deleted group')
	}
}

fn test_group_list() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Clear any existing groups by creating a fresh DB
	mydb = heromodels.new() or { panic('Failed to create fresh DB: ${err}') }

	// Initially should be empty
	initial_list := mydb.group.list() or { panic('Failed to list groups: ${err}') }
	initial_count := initial_list.len

	// Create multiple groups
	now := ourtime.now().unix()
	mut group1 := mydb.group.new(
		name:         'Group One'
		description:  'First test group'
		members:      [
			GroupMember{
				user_id:   1
				role:      .owner
				joined_at: now
			},
		]
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	) or { panic('Failed to create group1: ${err}') }

	mut group2 := mydb.group.new(
		name:         'Group Two'
		description:  'Second test group'
		members:      [
			GroupMember{
				user_id:   2
				role:      .admin
				joined_at: now
			},
			GroupMember{
				user_id:   3
				role:      .writer
				joined_at: now + 3600
			},
		]
		subgroups:    [u32(10)]
		parent_group: 0
		is_public:    false
	) or { panic('Failed to create group2: ${err}') }

	// Save both groups
	group1 = mydb.group.set(group1) or { panic('Failed to save group1: ${err}') }
	group2 = mydb.group.set(group2) or { panic('Failed to save group2: ${err}') }

	// List groups
	group_list := mydb.group.list() or { panic('Failed to list groups: ${err}') }

	// Should have 2 more groups than initially
	assert group_list.len == initial_count + 2

	// Find our groups in the list
	mut found_group1 := false
	mut found_group2 := false

	for grp in group_list {
		if grp.name == 'Group One' {
			found_group1 = true
			assert grp.is_public == true
			assert grp.members.len == 1
			assert grp.members[0].role == .owner
		}
		if grp.name == 'Group Two' {
			found_group2 = true
			assert grp.is_public == false
			assert grp.members.len == 2
			assert grp.subgroups.len == 1
		}
	}

	assert found_group1 == true
	assert found_group2 == true
}

fn test_group_edge_cases() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test group with no members
	mut empty_group := mydb.group.new(
		name:         'Empty Group'
		description:  'Group with no members'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	) or { panic('Failed to create empty group: ${err}') }

	empty_group = mydb.group.set(empty_group) or { panic('Failed to save empty group: ${err}') }

	retrieved_empty := mydb.group.get(empty_group.id) or {
		panic('Failed to get empty group: ${err}')
	}
	assert retrieved_empty.members.len == 0
	assert retrieved_empty.subgroups.len == 0
	assert retrieved_empty.is_public == true

	// Test group with many members
	now := ourtime.now().unix()
	mut many_members := []GroupMember{}
	for i in 0 .. 100 {
		many_members << GroupMember{
			user_id:   u32(i + 1)
			role:      if i % 4 == 0 {
				.owner
			} else if i % 4 == 1 {
				.admin
			} else if i % 4 == 2 {
				.writer
			} else {
				.reader
			}
			joined_at: now + i64(i * 60) // Different join times
		}
	}

	mut large_group := mydb.group.new(
		name:         'Large Group'
		description:  'Group with many members'
		members:      many_members
		subgroups:    []u32{len: 50, init: u32(index + 1000)} // 50 subgroups
		parent_group: 999
		is_public:    false
	) or { panic('Failed to create large group: ${err}') }

	large_group = mydb.group.set(large_group) or { panic('Failed to save large group: ${err}') }

	retrieved_large := mydb.group.get(large_group.id) or {
		panic('Failed to get large group: ${err}')
	}
	assert retrieved_large.members.len == 100
	assert retrieved_large.subgroups.len == 50
	assert retrieved_large.parent_group == 999

	// Verify member roles are preserved
	mut role_counts := map[GroupRole]int{}
	for member in retrieved_large.members {
		role_counts[member.role]++
	}
	assert role_counts[GroupRole.owner] == 25
	assert role_counts[GroupRole.admin] == 25
	assert role_counts[GroupRole.writer] == 25
	assert role_counts[GroupRole.reader] == 25

	// Test group with empty strings
	mut minimal_group := mydb.group.new(
		name:         ''
		description:  ''
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    false
	) or { panic('Failed to create minimal group: ${err}') }

	minimal_group = mydb.group.set(minimal_group) or { panic('Failed to save minimal group: ${err}') }

	retrieved_minimal := mydb.group.get(minimal_group.id) or {
		panic('Failed to get minimal group: ${err}')
	}
	assert retrieved_minimal.name == ''
	assert retrieved_minimal.description == ''
	assert retrieved_minimal.members.len == 0
	assert retrieved_minimal.is_public == false
}
