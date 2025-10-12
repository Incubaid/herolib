module heromodels

import incubaid.herolib.hero.db

fn test_message_new() ! {
	// Initialize DBMessages for testing
	mut mydb := db.new_test()!
	mut db_messages := DBMessages{
		db: &mydb
	}

	// Test creating a new message
	mut args := MessageArg{
		subject: 'Test Subject'
		message: 'This is a test message.'
		parent:  0
		author:  1
		to:      [u32(2), u32(3)]
		cc:      [u32(4), u32(5)]
	}

	message := db_messages.new(args)!

	assert message.subject == 'Test Subject'
	assert message.message == 'This is a test message.'
	assert message.parent == 0
	assert message.author == 1
	assert message.to.len == 2
	assert message.to[0] == 2
	assert message.to[1] == 3
	assert message.cc.len == 2
	assert message.cc[0] == 4
	assert message.cc[1] == 5
	assert message.updated_at > 0

	println('✓ Message new test passed!')
}

fn test_message_crud_operations() ! {
	// Initialize DBMessages for testing
	mut mydb := db.new_test()!
	mut db_messages := DBMessages{
		db: &mydb
	}

	// Create a new message
	mut args := MessageArg{
		subject: 'CRUD Test Subject'
		message: 'This is a test message for CRUD operations.'
		parent:  0
		author:  1
		to:      [u32(2), u32(3)]
		cc:      [u32(4), u32(5)]
	}

	mut message := db_messages.new(args)!

	// Test set operation
	message = db_messages.set(message)!
	original_id := message.id

	// Test get operation
	retrieved_message := db_messages.get(original_id)!
	assert retrieved_message.subject == 'CRUD Test Subject'
	assert retrieved_message.message == 'This is a test message for CRUD operations.'
	assert retrieved_message.parent == 0
	assert retrieved_message.author == 1
	assert retrieved_message.id == original_id
	assert retrieved_message.to.len == 2
	assert retrieved_message.to[0] == 2
	assert retrieved_message.to[1] == 3
	assert retrieved_message.cc.len == 2
	assert retrieved_message.cc[0] == 4
	assert retrieved_message.cc[1] == 5

	// Test exist operation
	exists := db_messages.exist(original_id)!
	assert exists == true

	// Test update
	mut updated_args := MessageArg{
		subject: 'Updated Test Subject'
		message: 'This is an updated test message.'
		parent:  10
		author:  2
		to:      [u32(6)]
		cc:      [u32(7), u32(8), u32(9)]
	}

	mut updated_message := db_messages.new(updated_args)!
	updated_message.id = original_id
	updated_message = db_messages.set(updated_message)!

	// Verify update
	final_message := db_messages.get(original_id)!
	assert final_message.subject == 'Updated Test Subject'
	assert final_message.message == 'This is an updated test message.'
	assert final_message.parent == 10
	assert final_message.author == 2
	assert final_message.to.len == 1
	assert final_message.to[0] == 6
	assert final_message.cc.len == 3
	assert final_message.cc[0] == 7
	assert final_message.cc[1] == 8
	assert final_message.cc[2] == 9

	// Test delete operation
	db_messages.delete(original_id)!

	// Verify deletion
	exists_after_delete := db_messages.exist(original_id)!
	assert exists_after_delete == false

	println('✓ Message CRUD operations test passed!')
}

fn test_message_encoding_decoding() ! {
	// Initialize DBMessages for testing
	mut mydb := db.new_test()!
	mut db_messages := DBMessages{
		db: &mydb
	}

	// Create a new message with all fields populated
	mut args := MessageArg{
		subject: 'Encoding Test Subject'
		message: 'This is a test message for encoding/decoding.'
		parent:  5
		author:  10
		to:      [u32(20), u32(30), u32(40)]
		cc:      [u32(50), u32(60)]
	}

	mut message := db_messages.new(args)!

	// Add send_log data manually
	mut send_log1 := SendLog{
		to:        [u32(100), u32(101)]
		cc:        [u32(102)]
		status:    .sent
		timestamp: 1678886400 // Example timestamp
	}
	mut send_log2 := SendLog{
		to:        [u32(200)]
		cc:        []u32{}
		status:    .received
		timestamp: 1678886500 // Example timestamp
	}
	message.send_log = [send_log1, send_log2]

	// Save the message
	message = db_messages.set(message)!
	message_id := message.id

	// Retrieve and verify all fields were properly encoded/decoded
	retrieved_message := db_messages.get(message_id)!

	assert retrieved_message.subject == 'Encoding Test Subject'
	assert retrieved_message.message == 'This is a test message for encoding/decoding.'
	assert retrieved_message.parent == 5
	assert retrieved_message.author == 10
	assert retrieved_message.to.len == 3
	assert retrieved_message.to[0] == 20
	assert retrieved_message.to[1] == 30
	assert retrieved_message.to[2] == 40
	assert retrieved_message.cc.len == 2
	assert retrieved_message.cc[0] == 50
	assert retrieved_message.cc[1] == 60

	// Verify send_log
	assert retrieved_message.send_log.len == 2
	assert retrieved_message.send_log[0].to.len == 2
	assert retrieved_message.send_log[0].to[0] == 100
	assert retrieved_message.send_log[0].to[1] == 101
	assert retrieved_message.send_log[0].cc.len == 1
	assert retrieved_message.send_log[0].cc[0] == 102
	assert retrieved_message.send_log[0].status == .sent
	assert retrieved_message.send_log[0].timestamp == 1678886400

	assert retrieved_message.send_log[1].to.len == 1
	assert retrieved_message.send_log[1].to[0] == 200
	assert retrieved_message.send_log[1].cc.len == 0
	assert retrieved_message.send_log[1].status == .received
	assert retrieved_message.send_log[1].timestamp == 1678886500

	println('✓ Message encoding/decoding test passed!')
}

fn test_message_type_name() ! {
	// Initialize DBMessages for testing
	mut mydb := db.new_test()!
	mut db_messages := DBMessages{
		db: &mydb
	}

	// Create a new message
	mut args := MessageArg{
		subject: 'Type Name Test Subject'
		message: 'This is a test message for type name.'
		parent:  0
		author:  1
		to:      []u32{}
		cc:      []u32{}
	}

	message := db_messages.new(args)!

	// Test type_name method
	type_name := message.type_name()
	assert type_name == 'messages'

	println('✓ Message type_name test passed!')
}

fn test_message_description() ! {
	// Initialize DBMessages for testing
	mut mydb := db.new_test()!
	mut db_messages := DBMessages{
		db: &mydb
	}

	// Create a new message
	mut args := MessageArg{
		subject: 'Description Test Subject'
		message: 'This is a test message for description method.'
		parent:  0
		author:  1
		to:      []u32{}
		cc:      []u32{}
	}

	message := db_messages.new(args)!

	// Test description method for each methodname
	assert message.description('set') == 'Create or update a message. Returns the ID of the message.'
	assert message.description('get') == 'Retrieve a message by ID. Returns the message object.'
	assert message.description('delete') == 'Delete a message by ID. Returns true if successful.'
	assert message.description('exist') == 'Check if a message exists by ID. Returns true or false.'
	assert message.description('list') == 'List all messages. Returns an array of message objects.'
	assert message.description('unknown') == 'This is generic method for the root object, TODO fill in, ...'

	println('✓ Message description test passed!')
}

fn test_message_example() ! {
	// Initialize DBMessages for testing
	mut mydb := db.new_test()!
	mut db_messages := DBMessages{
		db: &mydb
	}

	// Create a new message
	mut args := MessageArg{
		subject: 'Example Test Subject'
		message: 'This is a test message for example method.'
		parent:  0
		author:  1
		to:      []u32{}
		cc:      []u32{}
	}

	message := db_messages.new(args)!

	// Test example method for each methodname
	set_call, set_result := message.example('set')
	assert set_call == '{"message": {"subject": "Test Subject", "message": "This is a test message.", "parent": 0, "author": 1, "to": [2, 3], "cc": [4], "send_log": [{"to": [2], "cc": [], "status": "sent", "timestamp": 1678886400}]}}'
	assert set_result == '1'

	get_call, get_result := message.example('get')
	assert get_call == '{"id": 1}'
	assert get_result == '{"subject": "Test Subject", "message": "This is a test message.", "parent": 0, "author": 1, "to": [2, 3], "cc": [4], "send_log": [{"to": [2], "cc": [], "status": "sent", "timestamp": 1678886400}]}'

	delete_call, delete_result := message.example('delete')
	assert delete_call == '{"id": 1}'
	assert delete_result == 'true'

	exist_call, exist_result := message.example('exist')
	assert exist_call == '{"id": 1}'
	assert exist_result == 'true'

	list_call, list_result := message.example('list')
	assert list_call == '{}'
	assert list_result == '[{"subject": "Test Subject", "message": "This is a test message.", "parent": 0, "author": 1, "to": [2, 3], "cc": [4], "send_log": [{"to": [2], "cc": [], "status": "sent", "timestamp": 1678886400}]}]'

	unknown_call, unknown_result := message.example('unknown')
	assert unknown_call == '{}'
	assert unknown_result == '{}'

	println('✓ Message example test passed!')
}
