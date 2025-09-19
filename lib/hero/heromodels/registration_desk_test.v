module heromodels

import freeflowuniverse.herolib.hero.db

fn test_registration_desk_new() ! {
	// Initialize DBRegistrationDesk for testing
	mut mydb := db.new_test()!
	mut db_registration_desk := DBRegistrationDesk{
		db: &mydb
	}

	// Test creating a new registration desk
	mut args := RegistrationDeskArg{
		name:               "test_registration_desk"
		description:        "Test registration desk for unit testing"
		fs_items:           [u32(1001), u32(1002)]
		white_list:         [u32(2001), u32(2002), u32(2003)]
		white_list_accepted: [u32(3001)]
		black_list:         [u32(4001), u32(4002)]
		start_time:         "2025-01-01 10:00:00"
		end_time:           "2025-01-01 11:00:00"
		acceptance_required: true
		securitypolicy:     0
		tags:               ["test", "registration"]
		messages:           []
	}

	registration_desk := db_registration_desk.new(args)!

	assert registration_desk.name == "test_registration_desk"
	assert registration_desk.description == "Test registration desk for unit testing"
	assert registration_desk.fs_items.len == 2
	assert registration_desk.fs_items[0].fs_item == 1001
	assert registration_desk.fs_items[0].cat == ""
	assert registration_desk.fs_items[0].public == false
	assert registration_desk.fs_items[1].fs_item == 1002
	assert registration_desk.fs_items[1].cat == ""
	assert registration_desk.fs_items[1].public == false
	assert registration_desk.white_list == [u32(2001), u32(2002), u32(2003)]
	assert registration_desk.white_list_accepted == [u32(3001)]
	assert registration_desk.black_list == [u32(4001), u32(4002)]
	assert registration_desk.acceptance_required == true
	assert registration_desk.registrations.len == 0

	println("✓ RegistrationDesk new test passed!")
}

fn test_registration_desk_crud_operations() ! {
	// Initialize DBRegistrationDesk for testing
	mut mydb := db.new_test()!
	mut db_registration_desk := DBRegistrationDesk{
		db: &mydb
	}

	// Create a new registration desk
	mut args := RegistrationDeskArg{
		name:               "crud_test_registration_desk"
		description:        "Test registration desk for CRUD operations"
		fs_items:           [u32(1001), u32(1002)]
		white_list:         [u32(2001), u32(2002)]
		white_list_accepted: [u32(3001)]
		black_list:         [u32(4001)]
		start_time:         "2025-01-01 10:00:00"
		end_time:           "2025-01-01 11:00:00"
		acceptance_required: false
		securitypolicy:     0
		tags:               ["crud", "test"]
		messages:           []
	}

	mut registration_desk := db_registration_desk.new(args)!

	// Test set operation
	registration_desk = db_registration_desk.set(registration_desk)!
	original_id := registration_desk.id

	// Test get operation
	retrieved_desk := db_registration_desk.get(original_id)!
	assert retrieved_desk.name == "crud_test_registration_desk"
	assert retrieved_desk.description == "Test registration desk for CRUD operations"
	assert retrieved_desk.fs_items.len == 2
	assert retrieved_desk.fs_items[0].fs_item == 1001
	assert retrieved_desk.fs_items[0].cat == ""
	assert retrieved_desk.fs_items[0].public == false
	assert retrieved_desk.fs_items[1].fs_item == 1002
	assert retrieved_desk.fs_items[1].cat == ""
	assert retrieved_desk.fs_items[1].public == false
	assert retrieved_desk.white_list == [u32(2001), u32(2002)]
	assert retrieved_desk.white_list_accepted == [u32(3001)]
	assert retrieved_desk.black_list == [u32(4001)]
	assert retrieved_desk.acceptance_required == false
	assert retrieved_desk.id == original_id

	// Test exist operation
	exists := db_registration_desk.exist(original_id)!
	assert exists == true

	// Test update
	mut updated_args := RegistrationDeskArg{
		name:               "updated_registration_desk"
		description:        "Updated test registration desk"
		fs_items:           [u32(1003)]
		white_list:         [u32(2003), u32(2004)]
		white_list_accepted: [u32(3002)]
		black_list:         [u32(4002), u32(4003)]
		start_time:         "2025-01-01 12:00:00"
		end_time:           "2025-01-01 13:00:00"
		acceptance_required: true
		securitypolicy:     0
		tags:               ["updated", "test"]
		messages:           []
	}

	mut updated_desk := db_registration_desk.new(updated_args)!
	updated_desk.id = original_id

	updated_desk = db_registration_desk.set(updated_desk)!

	// Verify update
	final_desk := db_registration_desk.get(original_id)!
	assert final_desk.name == "updated_registration_desk"
	assert final_desk.description == "Updated test registration desk"
	assert final_desk.fs_items.len == 1
	assert final_desk.fs_items[0].fs_item == 1003
	assert final_desk.fs_items[0].cat == ""
	assert final_desk.fs_items[0].public == false
	assert final_desk.white_list == [u32(2003), u32(2004)]
	assert final_desk.white_list_accepted == [u32(3002)]
	assert final_desk.black_list == [u32(4002), u32(4003)]
	assert final_desk.acceptance_required == true

	// Test delete operation
	db_registration_desk.delete(original_id)!

	// Verify deletion
	exists_after_delete := db_registration_desk.exist(original_id)!
	assert exists_after_delete == false

	println("✓ RegistrationDesk CRUD operations test passed!")
}

fn test_registration_desk_registrations_encoding_decoding() ! {
	// Initialize DBRegistrationDesk for testing
	mut mydb := db.new_test()!
	mut db_registration_desk := DBRegistrationDesk{
		db: &mydb
	}

	// Create a new registration desk
	mut args := RegistrationDeskArg{
		name:               "registrations_test_desk"
		description:        "Test registration desk for registrations encoding/decoding"
		fs_items:           []
		white_list:         []
		white_list_accepted: []
		black_list:         []
		start_time:         "2025-01-01 10:00:00"
		end_time:           "2025-01-01 11:00:00"
		acceptance_required: true
		securitypolicy:     0
		tags:               []
		messages:           []
	}

	mut registration_desk := db_registration_desk.new(args)!

	// Add some registrations manually
	mut registration1 := Registration{
		user_id:               100
		accepted:              true
		accepted_by:           200
		timestamp:             1234567890
		timestamp_acceptation: 1234567900
	}

	mut registration2 := Registration{
		user_id:               101
		accepted:              false
		accepted_by:           0
		timestamp:             1234567891
		timestamp_acceptation: 0
	}

	registration_desk.registrations = [registration1, registration2]

	// Save the registration desk
	registration_desk = db_registration_desk.set(registration_desk)!
	registration_desk_id := registration_desk.id

	// Retrieve and verify all fields were properly encoded/decoded
	retrieved_desk := db_registration_desk.get(registration_desk_id)!

	assert retrieved_desk.registrations.len == 2

	// Verify first registration details
	assert retrieved_desk.registrations[0].user_id == 100
	assert retrieved_desk.registrations[0].accepted == true
	assert retrieved_desk.registrations[0].accepted_by == 200
	assert retrieved_desk.registrations[0].timestamp == 1234567890
	assert retrieved_desk.registrations[0].timestamp_acceptation == 1234567900

	// Verify second registration details
	assert retrieved_desk.registrations[1].user_id == 101
	assert retrieved_desk.registrations[1].accepted == false
	assert retrieved_desk.registrations[1].accepted_by == 0
	assert retrieved_desk.registrations[1].timestamp == 1234567891
	assert retrieved_desk.registrations[1].timestamp_acceptation == 0

	println("✓ RegistrationDesk registrations encoding/decoding test passed!")
}

fn test_registration_desk_type_name() ! {
	// Initialize DBRegistrationDesk for testing
	mut mydb := db.new_test()!
	mut db_registration_desk := DBRegistrationDesk{
		db: &mydb
	}

	// Create a new registration desk
	mut args := RegistrationDeskArg{
		name:               "type_test_desk"
		description:        "Test registration desk for type name"
		fs_items:           []
		white_list:         []
		white_list_accepted: []
		black_list:         []
		start_time:         "2025-01-01 10:00:00"
		end_time:           "2025-01-01 11:00:00"
		acceptance_required: false
		securitypolicy:     0
		tags:               []
		messages:           []
	}

	registration_desk := db_registration_desk.new(args)!

	// Test type_name method
	type_name := registration_desk.type_name()
	assert type_name == "registration_desk"

	println("✓ RegistrationDesk type_name test passed!")
}

fn test_registration_desk_description() ! {
	// Initialize DBRegistrationDesk for testing
	mut mydb := db.new_test()!
	mut db_registration_desk := DBRegistrationDesk{
		db: &mydb
	}

	// Create a new registration desk
	mut args := RegistrationDeskArg{
		name:               "description_test_desk"
		description:        "Test registration desk for description"
		fs_items:           []
		white_list:         []
		white_list_accepted: []
		black_list:         []
		start_time:         "2025-01-01 10:00:00"
		end_time:           "2025-01-01 11:00:00"
		acceptance_required: false
		securitypolicy:     0
		tags:               []
		messages:           []
	}

	registration_desk := db_registration_desk.new(args)!

	// Test description method for each methodname
	assert registration_desk.description("set") == "Create or update a registration desk. Returns the ID of the registration desk."
	assert registration_desk.description("get") == "Retrieve a registration desk by ID. Returns the registration desk object."
	assert registration_desk.description("delete") == "Delete a registration desk by ID. Returns true if successful."
	assert registration_desk.description("exist") == "Check if a registration desk exists by ID. Returns true or false."
	assert registration_desk.description("list") == "List all registration desks. Returns an array of registration desk objects."
	assert registration_desk.description("unknown") == "This is generic method for the root object, TODO fill in, ..."

	println("✓ RegistrationDesk description test passed!")
}

fn test_registration_desk_example() ! {
	// Initialize DBRegistrationDesk for testing
	mut mydb := db.new_test()!
	mut db_registration_desk := DBRegistrationDesk{
		db: &mydb
	}

	// Create a new registration desk
	mut args := RegistrationDeskArg{
		name:               "example_test_desk"
		description:        "Test registration desk for example"
		fs_items:           []
		white_list:         []
		white_list_accepted: []
		black_list:         []
		start_time:         "2025-01-01 10:00:00"
		end_time:           "2025-01-01 11:00:00"
		acceptance_required: false
		securitypolicy:     0
		tags:               []
		messages:           []
	}

	registration_desk := db_registration_desk.new(args)!

	// Test example method for each methodname
	set_call, set_result := registration_desk.example("set")
	assert set_call == '{"registration_desk": {"name": "event_registration", "description": "Registration desk for team meeting", "fs_items": [{"fs_item": 1001, "cat": "agenda", "public": true}], "white_list": [100, 101], "white_list_accepted": [102], "black_list": [200], "start_time": 1672564800, "end_time": 1672568400, "acceptance_required": true, "registrations": [{"user_id": 300, "accepted": true, "accepted_by": 400, "timestamp": 1672564900, "timestamp_acceptation": 1672565000}]}}'
	assert set_result == "1"

	get_call, get_result := registration_desk.example("get")
	assert get_call == '{"id": 1}'
	assert get_result == '{"name": "event_registration", "description": "Registration desk for team meeting", "fs_items": [{"fs_item": 1001, "cat": "agenda", "public": true}], "white_list": [100, 101], "white_list_accepted": [102], "black_list": [200], "start_time": 1672564800, "end_time": 1672568400, "acceptance_required": true, "registrations": [{"user_id": 300, "accepted": true, "accepted_by": 400, "timestamp": 1672564900, "timestamp_acceptation": 1672565000}]}'

	delete_call, delete_result := registration_desk.example("delete")
	assert delete_call == '{"id": 1}'
	assert delete_result == "true"

	exist_call, exist_result := registration_desk.example("exist")
	assert exist_call == '{"id": 1}'
	assert exist_result == "true"

	list_call, list_result := registration_desk.example("list")
	assert list_call == '{}'
	assert list_result == '[{"name": "event_registration", "description": "Registration desk for team meeting", "fs_items": [], "white_list": [], "white_list_accepted": [], "black_list": [], "start_time": 1672564800, "end_time": 1672568400, "acceptance_required": true, "registrations": []}]'

	unknown_call, unknown_result := registration_desk.example("unknown")
	assert unknown_call == '{}'
	assert unknown_result == '{}'

	println("✓ RegistrationDesk example test passed!")
}

fn test_registration_desk_list() ! {
	// Clear the test database first
	mut mydb_clear := db.new_test()!
	mydb_clear.redis.flushdb()!

	// Initialize DBRegistrationDesk for testing
	mut mydb := db.new_test()!
	mut db_registration_desk := DBRegistrationDesk{
		db: &mydb
	}

	// Create a few registration desks
	mut args1 := RegistrationDeskArg{
		name:               "list_test_desk_1"
		description:        "First test registration desk for list operations"
		fs_items:           []
		white_list:         []
		white_list_accepted: []
		black_list:         []
		start_time:         "2025-01-01 10:00:00"
		end_time:           "2025-01-01 11:00:00"
		acceptance_required: false
		securitypolicy:     0
		tags:               []
		messages:           []
	}

	mut args2 := RegistrationDeskArg{
		name:               "list_test_desk_2"
		description:        "Second test registration desk for list operations"
		fs_items:           []
		white_list:         []
		white_list_accepted: []
		black_list:         []
		start_time:         "2025-01-01 10:00:00"
		end_time:           "2025-01-01 11:00:00"
		acceptance_required: true
		securitypolicy:     0
		tags:               []
		messages:           []
	}

	mut desk1 := db_registration_desk.new(args1)!
	mut desk2 := db_registration_desk.new(args2)!

	// Save the registration desks
	desk1 = db_registration_desk.set(desk1)!
	desk2 = db_registration_desk.set(desk2)!

	// Test list by name
	mut listed_desks := db_registration_desk.list(RegistrationDeskListArg{
		name: "list_test_desk_1"
	})!

	assert listed_desks.len == 1
	assert listed_desks[0].name == "list_test_desk_1"

	// Test list by description
	listed_desks = db_registration_desk.list(RegistrationDeskListArg{
		description: "test registration desk"
	})!

	assert listed_desks.len == 2

	// Test list with limit
	listed_desks = db_registration_desk.list(RegistrationDeskListArg{
		description: "test registration desk"
		limit: 1
	})!

	assert listed_desks.len == 1

	println("✓ RegistrationDesk list test passed!")
}

fn test_registration_desk_fs_items_encoding_decoding() ! {
	// Initialize DBRegistrationDesk for testing
	mut mydb := db.new_test()!
	mut db_registration_desk := DBRegistrationDesk{
		db: &mydb
	}

	// Create a new registration desk
	mut args := RegistrationDeskArg{
		name:               "fs_items_test_desk"
		description:        "Test registration desk for fs_items encoding/decoding"
		fs_items:           [u32(1001), u32(1002)]
		white_list:         []
		white_list_accepted: []
		black_list:         []
		start_time:         "2025-01-01 10:00:00"
		end_time:           "2025-01-01 11:00:00"
		acceptance_required: false
		securitypolicy:     0
		tags:               []
		messages:           []
	}

	mut registration_desk := db_registration_desk.new(args)!

	// Add file attachments manually with custom values
	mut fs_item1 := RegistrationFileAttachment{
		fs_item: 1001
		cat:     "agenda"
		public:  true
	}

	mut fs_item2 := RegistrationFileAttachment{
		fs_item: 2002
		cat:     "minutes"
		public:  false
	}

	registration_desk.fs_items = [fs_item1, fs_item2]

	// Save the registration desk
	registration_desk = db_registration_desk.set(registration_desk)!
	registration_desk_id := registration_desk.id

	// Retrieve and verify all fields were properly encoded/decoded
	retrieved_desk := db_registration_desk.get(registration_desk_id)!

	assert retrieved_desk.fs_items.len == 2

	// Verify first file attachment details
	assert retrieved_desk.fs_items[0].fs_item == 1001
	assert retrieved_desk.fs_items[0].cat == "agenda"
	assert retrieved_desk.fs_items[0].public == true

	// Verify second file attachment details
	assert retrieved_desk.fs_items[1].fs_item == 2002
	assert retrieved_desk.fs_items[1].cat == "minutes"
	assert retrieved_desk.fs_items[1].public == false

	println("✓ RegistrationDesk fs_items encoding/decoding test passed!")
}
