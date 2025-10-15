module heromodels

import incubaid.herolib.hero.db

fn test_chat_group_new() ! {
	// Initialize DBChatGroup for testing
	mut mydb := db.new_test()!
	mut db_chat_group := DBChatGroup{
		db: &mydb
	}

	// Test creating a new chat group
	mut args := ChatGroupArg{
		name:           'test_chat_group'
		description:    'Test chat group for unit testing'
		chat_type:      .public_channel
		last_activity:  1678886400
		is_archived:    false
		group_id:       1
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	chat_group := db_chat_group.new(args)!

	assert chat_group.name == 'test_chat_group'
	assert chat_group.description == 'Test chat group for unit testing'
	assert chat_group.chat_type == .public_channel
	assert chat_group.last_activity == 1678886400
	assert chat_group.is_archived == false
	assert chat_group.group_id == 1
	assert chat_group.updated_at > 0

	println('✓ ChatGroup new test passed!')
}

fn test_chat_group_crud_operations() ! {
	// Initialize DBChatGroup for testing
	mut mydb := db.new_test()!
	mut db_chat_group := DBChatGroup{
		db: &mydb
	}

	// Create a new chat group
	mut args := ChatGroupArg{
		name:           'crud_test_chat_group'
		description:    'Test chat group for CRUD operations'
		chat_type:      .private_channel
		last_activity:  1678886400
		is_archived:    false
		group_id:       2
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	mut chat_group := db_chat_group.new(args)!

	// Test set operation
	chat_group = db_chat_group.set(chat_group)!
	original_id := chat_group.id

	// Test get operation
	retrieved_chat_group := db_chat_group.get(original_id)!
	assert retrieved_chat_group.name == 'crud_test_chat_group'
	assert retrieved_chat_group.description == 'Test chat group for CRUD operations'
	assert retrieved_chat_group.chat_type == .private_channel
	assert retrieved_chat_group.last_activity == 1678886400
	assert retrieved_chat_group.is_archived == false
	assert retrieved_chat_group.group_id == 2
	assert retrieved_chat_group.id == original_id

	// Test exist operation
	exists := db_chat_group.exist(original_id)!
	assert exists == true

	// Test update
	mut updated_args := ChatGroupArg{
		name:           'updated_chat_group'
		description:    'Updated test chat group'
		chat_type:      .direct_message
		last_activity:  1678886500
		is_archived:    true
		group_id:       3
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	mut updated_chat_group := db_chat_group.new(updated_args)!
	updated_chat_group.id = original_id
	updated_chat_group = db_chat_group.set(updated_chat_group)!

	// Verify update
	final_chat_group := db_chat_group.get(original_id)!
	assert final_chat_group.name == 'updated_chat_group'
	assert final_chat_group.description == 'Updated test chat group'
	assert final_chat_group.chat_type == .direct_message
	assert final_chat_group.last_activity == 1678886500
	assert final_chat_group.is_archived == true
	assert final_chat_group.group_id == 3

	// Test delete operation
	db_chat_group.delete(original_id)!

	// Verify deletion
	exists_after_delete := db_chat_group.exist(original_id)!
	assert exists_after_delete == false

	println('✓ ChatGroup CRUD operations test passed!')
}

fn test_chat_group_encoding_decoding() ! {
	// Initialize DBChatGroup for testing
	mut mydb := db.new_test()!
	mut db_chat_group := DBChatGroup{
		db: &mydb
	}

	// Create a new chat group
	mut args := ChatGroupArg{
		name:           'encoding_test_chat_group'
		description:    'Test chat group for encoding/decoding'
		chat_type:      .group_message
		last_activity:  1678886600
		is_archived:    true
		group_id:       4
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	mut chat_group := db_chat_group.new(args)!

	// Save the chat group
	chat_group = db_chat_group.set(chat_group)!
	chat_group_id := chat_group.id

	// Retrieve and verify all fields were properly encoded/decoded
	retrieved_chat_group := db_chat_group.get(chat_group_id)!

	assert retrieved_chat_group.name == 'encoding_test_chat_group'
	assert retrieved_chat_group.description == 'Test chat group for encoding/decoding'
	assert retrieved_chat_group.chat_type == .group_message
	assert retrieved_chat_group.last_activity == 1678886600
	assert retrieved_chat_group.is_archived == true
	assert retrieved_chat_group.group_id == 4

	println('✓ ChatGroup encoding/decoding test passed!')
}

fn test_chat_group_type_name() ! {
	// Initialize DBChatGroup for testing
	mut mydb := db.new_test()!
	mut db_chat_group := DBChatGroup{
		db: &mydb
	}

	// Create a new chat group
	mut args := ChatGroupArg{
		name:           'type_test_chat_group'
		description:    'Test chat group for type name'
		chat_type:      .public_channel
		last_activity:  1678886400
		is_archived:    false
		group_id:       1
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	chat_group := db_chat_group.new(args)!

	// Test type_name method
	type_name := chat_group.type_name()
	assert type_name == 'chat_group'

	println('✓ ChatGroup type_name test passed!')
}

fn test_chat_group_description() ! {
	// Initialize DBChatGroup for testing
	mut mydb := db.new_test()!
	mut db_chat_group := DBChatGroup{
		db: &mydb
	}

	// Create a new chat group
	mut args := ChatGroupArg{
		name:           'description_test_chat_group'
		description:    'Test chat group for description'
		chat_type:      .public_channel
		last_activity:  1678886400
		is_archived:    false
		group_id:       1
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	chat_group := db_chat_group.new(args)!

	// Test description method for each methodname
	assert chat_group.description('set') == 'Create or update a chat group. Returns the ID of the chat group.'
	assert chat_group.description('get') == 'Retrieve a chat group by ID. Returns the chat group object.'
	assert chat_group.description('delete') == 'Delete a chat group by ID. Returns true if successful.'
	assert chat_group.description('exist') == 'Check if a chat group exists by ID. Returns true or false.'
	assert chat_group.description('list') == 'List all chat groups. Returns an array of chat group objects.'
	assert chat_group.description('unknown') == 'This is generic method for the root object, TODO fill in, ...'

	println('✓ ChatGroup description test passed!')
}

fn test_chat_group_example() ! {
	// Initialize DBChatGroup for testing
	mut mydb := db.new_test()!
	mut db_chat_group := DBChatGroup{
		db: &mydb
	}

	// Create a new chat group
	mut args := ChatGroupArg{
		name:           'example_test_chat_group'
		description:    'Test chat group for example'
		chat_type:      .public_channel
		last_activity:  1678886400
		is_archived:    false
		group_id:       1
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	chat_group := db_chat_group.new(args)!

	// Test example method for each methodname
	set_call, set_result := chat_group.example('set')
	assert set_call == '{"chat_group": {"name": "General Chat", "description": "A general chat group", "chat_type": "public_channel", "last_activity": 1678886400, "is_archived": false, "group_id": 1}}'
	assert set_result == '1'

	get_call, get_result := chat_group.example('get')
	assert get_call == '{"id": 1}'
	assert get_result == '{"name": "General Chat", "description": "A general chat group", "chat_type": "public_channel", "last_activity": 1678886400, "is_archived": false, "group_id": 1}'

	delete_call, delete_result := chat_group.example('delete')
	assert delete_call == '{"id": 1}'
	assert delete_result == 'true'

	exist_call, exist_result := chat_group.example('exist')
	assert exist_call == '{"id": 1}'
	assert exist_result == 'true'

	list_call, list_result := chat_group.example('list')
	assert list_call == '{}'
	assert list_result == '[{"name": "General Chat", "description": "A general chat group", "chat_type": "public_channel", "last_activity": 1678886400, "is_archived": false, "group_id": 1}]'

	unknown_call, unknown_result := chat_group.example('unknown')
	assert unknown_call == '{}'
	assert unknown_result == '{}'

	println('✓ ChatGroup example test passed!')
}
