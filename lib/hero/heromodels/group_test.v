module heromodels

import freeflowuniverse.herolib.hero.db

fn test_group_new() ! {
	// Initialize DBGroup for testing
	mut mydb := db.new_test()!
	mut db_group := DBGroup{
		db: &mydb
	}

	// Test creating a new group
	mut args := GroupArg{
		name:         'test_group'
		description:  'Test group for unit testing'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	}

	group := db_group.new(args)!
	
	assert group.name == 'test_group'
	assert group.description == 'Test group for unit testing'
	assert group.is_public == true
	assert group.members.len == 0
	assert group.subgroups.len == 0
	assert group.parent_group == 0
	assert group.updated_at > 0
	
	println('✓ Group new test passed!')
}

fn test_group_crud_operations() ! {
	// Initialize DBGroup for testing
	mut mydb := db.new_test()!
	mut db_group := DBGroup{
		db: &mydb
	}

	// Create a new group
	mut args := GroupArg{
		name:         'crud_test_group'
		description:  'Test group for CRUD operations'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    false
	}

	mut group := db_group.new(args)!

	// Test set operation
	group = db_group.set(group)!
	original_id := group.id

	// Test get operation
	retrieved_group := db_group.get(original_id)!
	assert retrieved_group.name == 'crud_test_group'
	assert retrieved_group.description == 'Test group for CRUD operations'
	assert retrieved_group.is_public == false
	assert retrieved_group.id == original_id

	// Test exist operation
	exists := db_group.exist(original_id)!
	assert exists == true

	// Test update
	mut updated_args := GroupArg{
		name:         'updated_group'
		description:  'Updated test group'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	}

	mut updated_group := db_group.new(updated_args)!
	updated_group.id = original_id
	updated_group = db_group.set(updated_group)!

	// Verify update
	final_group := db_group.get(original_id)!
	assert final_group.name == 'updated_group'
	assert final_group.description == 'Updated test group'
	assert final_group.is_public == true

	// Test delete operation
	db_group.delete(original_id)!
	
	// Verify deletion
	exists_after_delete := db_group.exist(original_id)!
	assert exists_after_delete == false
	
	println('✓ Group CRUD operations test passed!')
}

fn test_group_member_operations() ! {
	// Initialize DBGroup for testing
	mut mydb := db.new_test()!
	mut db_group := DBGroup{
		db: &mydb
	}

	// Create a new group
	mut args := GroupArg{
		name:         'member_test_group'
		description:  'Test group for member operations'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	}

	mut group := db_group.new(args)!
	group = db_group.set(group)!
	group_id := group.id

	// Test add_member
	group.add_member(100, .admin)
	group.add_member(101, .writer)
	group.add_member(102, .reader)

	// Save updated group
	group = db_group.set(group)!

	// Verify members were added
	updated_group := db_group.get(group_id)!
	assert updated_group.members.len == 3
	
	// Check first member
	assert updated_group.members[0].user_id == 100
	assert updated_group.members[0].role == .admin
	
	// Check second member
	assert updated_group.members[1].user_id == 101
	assert updated_group.members[1].role == .writer
	
	// Check third member
	assert updated_group.members[2].user_id == 102
	assert updated_group.members[2].role == .reader
	
	// Verify joined_at timestamps are set
	assert updated_group.members[0].joined_at > 0
	assert updated_group.members[1].joined_at > 0
	assert updated_group.members[2].joined_at > 0
	
	println('✓ Group member operations test passed!')
}

fn test_group_hierarchy_operations() ! {
	// Initialize DBGroup for testing
	mut mydb := db.new_test()!
	mut db_group := DBGroup{
		db: &mydb
	}

	// Create parent group
	mut parent_args := GroupArg{
		name:         'parent_group'
		description:  'Parent group'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	}

	mut parent_group := db_group.new(parent_args)!
	parent_group = db_group.set(parent_group)!
	parent_id := parent_group.id

	// Create child group
	mut child_args := GroupArg{
		name:         'child_group'
		description:  'Child group'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: parent_id
		is_public:    false
	}

	mut child_group := db_group.new(child_args)!
	child_group = db_group.set(child_group)!
	child_id := child_group.id

	// Add child to parent's subgroups
	parent_group.subgroups << child_id
	parent_group = db_group.set(parent_group)!

	// Verify hierarchy
	final_parent := db_group.get(parent_id)!
	final_child := db_group.get(child_id)!
	
	assert final_parent.subgroups.len == 1
	assert final_parent.subgroups[0] == child_id
	assert final_child.parent_group == parent_id
	
	println('✓ Group hierarchy operations test passed!')
}

fn test_group_list_operations() ! {
	// Initialize DBGroup for testing
	mut mydb := db.new_test()!
	mut db_group := DBGroup{
		db: &mydb
	}

	// Create public group
	mut public_args := GroupArg{
		name:         'public_group'
		description:  'Public group'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	}

	mut public_group := db_group.new(public_args)!
	public_group = db_group.set(public_group)!

	// Create private group
	mut private_args := GroupArg{
		name:         'private_group'
		description:  'Private group'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    false
	}

	mut private_group := db_group.new(private_args)!
	private_group = db_group.set(private_group)!

	// Create child group
	mut child_args := GroupArg{
		name:         'child_group'
		description:  'Child group'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: public_group.id
		is_public:    true
	}

	mut child_group := db_group.new(child_args)!
	child_group = db_group.set(child_group)!

	// Add child to parent's subgroups
	public_group.subgroups << child_group.id
	public_group = db_group.set(public_group)!

	// Test list with is_public filter
	public_list_args := GroupListArg{
		is_public:    true
		parent_group: 0
		limit:        100
	}

	public_groups := db_group.list(public_list_args)!
	assert public_groups.len >= 1
	
	found_public := false
	for group in public_groups {
		if group.id == public_group.id {
			found_public = true
			break
		}
	}
	assert found_public == true

	// Test list with parent_group filter
	parent_list_args := GroupListArg{
		is_public:    false
		parent_group: public_group.id
		limit:        100
	}

	parent_groups := db_group.list(parent_list_args)!
	assert parent_groups.len >= 1
	
	found_child := false
	for group in parent_groups {
		if group.id == child_group.id {
			found_child = true
			break
		}
	}
	assert found_child == true

	// Test list with both filters
	both_list_args := GroupListArg{
		is_public:    true
		parent_group: public_group.id
		limit:        100
	}

	both_groups := db_group.list(both_list_args)!
	assert both_groups.len >= 1
	
	found_child_public := false
	for group in both_groups {
		if group.id == child_group.id && group.is_public == true {
			found_child_public = true
			break
		}
	}
	assert found_child_public == true

	println('✓ Group list operations test passed!')
}

fn test_group_type_name() ! {
	// Initialize DBGroup for testing
	mut mydb := db.new_test()!
	mut db_group := DBGroup{
		db: &mydb
	}

	// Create a new group
	mut args := GroupArg{
		name:         'type_test_group'
		description:  'Test group for type name'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	}

	group := db_group.new(args)!
	
	// Test type_name method
	type_name := group.type_name()
	assert type_name == 'group'
	
	println('✓ Group type_name test passed!')
}

fn test_group_description() ! {
	// Initialize DBGroup for testing
	mut mydb := db.new_test()!
	mut db_group := DBGroup{
		db: &mydb
	}

	// Create a new group
	mut args := GroupArg{
		name:         'description_test_group'
		description:  'Test group for description'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	}

	group := db_group.new(args)!
	
	// Test description method for each methodname
	assert group.description('set') == 'Create or update a group. Returns the ID of the group.'
	assert group.description('get') == 'Retrieve a group by ID. Returns the group object.'
	assert group.description('delete') == 'Delete a group by ID. Returns true if successful.'
	assert group.description('exist') == 'Check if a group exists by ID. Returns true or false.'
	assert group.description('list') == 'List all groups. Returns an array of group objects.'
	assert group.description('unknown') == 'This is generic method for the root object, TODO fill in, ...'
	
	println('✓ Group description test passed!')
}

fn test_group_example() ! {
	// Initialize DBGroup for testing
	mut mydb := db.new_test()!
	mut db_group := DBGroup{
		db: &mydb
	}

	// Create a new group
	mut args := GroupArg{
		name:         'example_test_group'
		description:  'Test group for example'
		members:      []GroupMember{}
		subgroups:    []u32{}
		parent_group: 0
		is_public:    true
	}

	group := db_group.new(args)!
	
	// Test example method for each methodname
	set_call, set_result := group.example('set')
	assert set_call == '{"group": {"name": "Admins", "description": "Administrators group", "members": [], "subgroups": [], "parent_group": 0, "is_public": false}}'
	assert set_result == '1'

	get_call, get_result := group.example('get')
	assert get_call == '{"id": 1}'
	assert get_result == '{"name": "Admins", "description": "Administrators group", "members": [], "subgroups": [], "parent_group": 0, "is_public": false}'

	delete_call, delete_result := group.example('delete')
	assert delete_call == '{"id": 1}'
	assert delete_result == 'true'

	exist_call, exist_result := group.example('exist')
	assert exist_call == '{"id": 1}'
	assert exist_result == 'true'

	list_call, list_result := group.example('list')
	assert list_call == '{}'
	assert list_result == '[{"name": "Admins", "description": "Administrators group", "members": [], "subgroups": [], "parent_group": 0, "is_public": false}]'

	unknown_call, unknown_result := group.example('unknown')
	assert unknown_call == '{}'
	assert unknown_result == '{}'
	
	println('✓ Group example test passed!')
}

fn test_group_encoding_decoding() ! {
	// Initialize DBGroup for testing
	mut mydb := db.new_test()!
	mut db_group := DBGroup{
		db: &mydb
	}

	// Create a new group with members
	mut args := GroupArg{
		name:         'encoding_test_group'
		description:  'Test group for encoding/decoding'
		members:      []GroupMember{}
		subgroups:    [u32(10), u32(20), u32(30)]
		parent_group: 5
		is_public:    true
	}

	mut group := db_group.new(args)!
	
	// Add some members
	group.add_member(100, .admin)
	group.add_member(101, .writer)
	
	// Save the group
	group = db_group.set(group)!
	group_id := group.id

	// Retrieve and verify all fields were properly encoded/decoded
	retrieved_group := db_group.get(group_id)!
	
	assert retrieved_group.name == 'encoding_test_group'
	assert retrieved_group.description == 'Test group for encoding/decoding'
	assert retrieved_group.subgroups == [u32(10), u32(20), u32(30)]
	assert retrieved_group.parent_group == 5
	assert retrieved_group.is_public == true
	assert retrieved_group.members.len == 2
	
	// Verify member details
	assert retrieved_group.members[0].user_id == 100
	assert retrieved_group.members[0].role == .admin
	assert retrieved_group.members[1].user_id == 101
	assert retrieved_group.members[1].role == .writer
	
	println('✓ Group encoding/decoding test passed!')
}