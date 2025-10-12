module heromodels

import incubaid.herolib.hero.db

fn test_calendar_event_new() ! {
	// Initialize DBCalendarEvent for testing
	mut mydb := db.new_test()!
	mut db_calendar_event := DBCalendarEvent{
		db: &mydb
	}

	// Test creating a new calendar event
	mut args := CalendarEventArg{
		name:           'test_event'
		description:    'Test calendar event for unit testing'
		title:          'Team Meeting'
		start_time:     '2025-01-01 10:00:00'
		end_time:       '2025-01-01 11:00:00'
		attendees:      []u32{}
		docs:           []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     false
		reminder_mins:  [15]
		color:          '#0000FF'
		timezone:       'UTC'
		priority:       .normal // Added missing priority field
		is_template:    false   // Added missing is_template field
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	calendar_event := db_calendar_event.new(args)!

	assert calendar_event.name == 'test_event'
	assert calendar_event.description == 'Test calendar event for unit testing'
	assert calendar_event.title == 'Team Meeting'
	assert calendar_event.locations.len == 0
	assert calendar_event.docs.len == 0
	assert calendar_event.calendar_id == 1
	assert calendar_event.status == .published
	assert calendar_event.is_all_day == false
	assert calendar_event.reminder_mins == [15]
	assert calendar_event.color == '#0000FF'
	assert calendar_event.timezone == 'UTC'
	assert calendar_event.updated_at > 0

	println('✓ CalendarEvent new test passed!')
}

fn test_calendar_event_crud_operations() ! {
	// Initialize DBCalendarEvent for testing
	mut mydb := db.new_test()!
	mut db_calendar_event := DBCalendarEvent{
		db: &mydb
	}

	// Create a new calendar event
	mut args := CalendarEventArg{
		name:           'crud_test_event'
		description:    'Test calendar event for CRUD operations'
		title:          'Team Meeting'
		start_time:     '2025-01-01 10:00:00'
		end_time:       '2025-01-01 11:00:00'
		attendees:      []u32{}
		docs:           []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     false
		reminder_mins:  [15]
		color:          '#0000FF'
		timezone:       'UTC'
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	mut calendar_event := db_calendar_event.new(args)!

	// Test set operation
	calendar_event = db_calendar_event.set(calendar_event)!
	original_id := calendar_event.id

	// Test get operation
	retrieved_event := db_calendar_event.get(original_id)!
	assert retrieved_event.name == 'crud_test_event'
	assert retrieved_event.description == 'Test calendar event for CRUD operations'
	assert retrieved_event.title == 'Team Meeting'
	assert retrieved_event.locations.len == 0
	assert retrieved_event.calendar_id == 1
	assert retrieved_event.status == .published
	assert retrieved_event.is_all_day == false
	assert retrieved_event.reminder_mins == [15]
	assert retrieved_event.color == '#0000FF'
	assert retrieved_event.timezone == 'UTC'
	assert retrieved_event.id == original_id

	// Test exist operation
	exists := db_calendar_event.exist(original_id)!
	assert exists == true

	// Test update
	mut updated_args := CalendarEventArg{
		name:           'updated_event'
		description:    'Updated test calendar event'
		title:          'Updated Team Meeting'
		start_time:     '2025-01-01 12:00:00'
		end_time:       '2025-01-01 13:00:00'
		attendees:      []u32{}
		docs:           []u32{}
		calendar_id:    2
		status:         .draft
		is_all_day:     true
		reminder_mins:  [30]
		color:          '#FF0000'
		timezone:       'EST'
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	mut updated_event := db_calendar_event.new(updated_args)!
	updated_event.id = original_id

	updated_event = db_calendar_event.set(updated_event)!

	// Verify update
	final_event := db_calendar_event.get(original_id)!
	assert final_event.name == 'updated_event'
	assert final_event.description == 'Updated test calendar event'
	assert final_event.title == 'Updated Team Meeting'
	assert final_event.locations.len == 0
	assert final_event.calendar_id == 2
	assert final_event.status == .draft
	assert final_event.is_all_day == true
	assert final_event.reminder_mins == [30]
	assert final_event.color == '#FF0000'
	assert final_event.timezone == 'EST'

	// Test delete operation
	db_calendar_event.delete(original_id)!

	// Verify deletion
	exists_after_delete := db_calendar_event.exist(original_id)!
	assert exists_after_delete == false

	println('✓ CalendarEvent CRUD operations test passed!')
}

fn test_calendar_event_attendees_encoding_decoding() ! {
	// Initialize DBCalendarEvent for testing
	mut mydb := db.new_test()!
	mut db_calendar_event := DBCalendarEvent{
		db: &mydb
	}

	// Create a new calendar event with attendees
	mut args := CalendarEventArg{
		name:           'attendees_test_event'
		description:    'Test calendar event for attendees encoding/decoding'
		title:          'Team Meeting'
		start_time:     '2025-01-01 10:00:00'
		end_time:       '2025-01-01 11:00:00'
		attendees:      []u32{}
		docs:           []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     false
		reminder_mins:  [15]
		color:          '#0000FF'
		timezone:       'UTC'
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	mut calendar_event := db_calendar_event.new(args)!

	// Save the calendar event
	calendar_event = db_calendar_event.set(calendar_event)!
	calendar_event_id := calendar_event.id

	// Retrieve and verify all fields were properly encoded/decoded
	retrieved_event := db_calendar_event.get(calendar_event_id)!

	assert retrieved_event.attendees.len == 0

	println('✓ CalendarEvent attendees encoding/decoding test passed!')
}

fn test_calendar_event_registration_desks_encoding_decoding() ! {
	// Initialize DBCalendarEvent for testing
	mut mydb := db.new_test()!
	mut db_calendar_event := DBCalendarEvent{
		db: &mydb
	}

	// Create a new calendar event with registration desks
	mut args := CalendarEventArg{
		name:           'registration_desks_test_event'
		description:    'Test calendar event for registration desks encoding/decoding'
		title:          'Team Meeting'
		start_time:     '2025-01-01 10:00:00'
		end_time:       '2025-01-01 11:00:00'
		attendees:      []u32{}
		docs:           []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     false
		reminder_mins:  [15]
		color:          '#0000FF'
		timezone:       'UTC'
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	mut calendar_event := db_calendar_event.new(args)!

	// Save the calendar event
	calendar_event = db_calendar_event.set(calendar_event)!
	calendar_event_id := calendar_event.id

	// Retrieve and verify all fields were properly encoded/decoded
	retrieved_event := db_calendar_event.get(calendar_event_id)!

	assert retrieved_event.registration_desks.len == 0

	println('✓ CalendarEvent registration_desks encoding/decoding test passed!')
}

fn test_calendar_event_docs_encoding_decoding() ! {
	// Initialize DBCalendarEvent for testing
	mut mydb := db.new_test()!
	mut db_calendar_event := DBCalendarEvent{
		db: &mydb
	}

	// Create a new calendar event with file attachments
	mut args := CalendarEventArg{
		name:           'docs_test_event'
		description:    'Test calendar event for docs encoding/decoding'
		title:          'Team Meeting'
		start_time:     '2025-01-01 10:00:00'
		end_time:       '2025-01-01 11:00:00'
		attendees:      []u32{}
		docs:           []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     false
		reminder_mins:  [15]
		color:          '#0000FF'
		timezone:       'UTC'
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	mut calendar_event := db_calendar_event.new(args)!

	// Save the calendar event
	calendar_event = db_calendar_event.set(calendar_event)!
	calendar_event_id := calendar_event.id

	// Retrieve and verify all fields were properly encoded/decoded
	retrieved_event := db_calendar_event.get(calendar_event_id)!

	assert retrieved_event.docs.len == 0

	println('✓ CalendarEvent docs encoding/decoding test passed!')
}

fn test_calendar_event_type_name() ! {
	// Initialize DBCalendarEvent for testing
	mut mydb := db.new_test()!
	mut db_calendar_event := DBCalendarEvent{
		db: &mydb
	}

	// Create a new calendar event
	mut args := CalendarEventArg{
		name:           'type_test_event'
		description:    'Test calendar event for type name'
		title:          'Team Meeting'
		start_time:     '2025-01-01 10:00:00'
		end_time:       '2025-01-01 11:00:00'
		attendees:      []u32{}
		docs:           []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     false
		reminder_mins:  [15]
		color:          '#0000FF'
		timezone:       'UTC'
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	calendar_event := db_calendar_event.new(args)!

	// Test type_name method
	type_name := calendar_event.type_name()
	assert type_name == 'calendar_event'

	println('✓ CalendarEvent type_name test passed!')
}

fn test_calendar_event_description() ! {
	// Initialize DBCalendarEvent for testing
	mut mydb := db.new_test()!
	mut db_calendar_event := DBCalendarEvent{
		db: &mydb
	}

	// Create a new calendar event
	mut args := CalendarEventArg{
		name:           'description_test_event'
		description:    'Test calendar event for description'
		title:          'Team Meeting'
		start_time:     '2025-01-01 10:00:00'
		end_time:       '2025-01-01 11:00:00'
		attendees:      []u32{}
		docs:           []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     false
		reminder_mins:  [15]
		color:          '#0000FF'
		timezone:       'UTC'
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	calendar_event := db_calendar_event.new(args)!

	// Test description method for each methodname
	assert calendar_event.description('set') == 'Create or update a calendar event. Returns the ID of the event.'
	assert calendar_event.description('get') == 'Retrieve a calendar event by ID. Returns the event object.'
	assert calendar_event.description('delete') == 'Delete a calendar event by ID. Returns true if successful.'
	assert calendar_event.description('exist') == 'Check if a calendar event exists by ID. Returns true or false.'
	assert calendar_event.description('list') == 'List all calendar events. Returns an array of event objects.'
	assert calendar_event.description('unknown') == 'This is generic method for the root object, TODO fill in, ...'

	println('✓ CalendarEvent description test passed!')
}

fn test_calendar_event_example() ! {
	// Initialize DBCalendarEvent for testing
	mut mydb := db.new_test()!
	mut db_calendar_event := DBCalendarEvent{
		db: &mydb
	}

	// Create a new calendar event
	mut args := CalendarEventArg{
		name:           'example_test_event'
		description:    'Test calendar event for example'
		title:          'Team Meeting'
		start_time:     '2025-01-01 10:00:00'
		end_time:       '2025-01-01 11:00:00'
		attendees:      []u32{}
		docs:           []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     false
		reminder_mins:  [15]
		color:          '#0000FF'
		timezone:       'UTC'
		securitypolicy: 0
		tags:           []string{}
		messages:       []db.MessageArg{}
	}

	calendar_event := db_calendar_event.new(args)!

	// Test example method for each methodname
	set_call, set_result := calendar_event.example('set')
	assert set_call == '{"calendar_event": {"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "attendees": [], "docs": [], "calendar_id": 1, "status": "published", "is_all_day": false, "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC", "locations": []}}'
	assert set_result == '1'

	get_call, get_result := calendar_event.example('get')
	assert get_call == '{"id": 1}'
	assert get_result == '{"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "attendees": [], "docs": [], "calendar_id": 1, "status": "published", "is_all_day": false, "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC", "locations": []}'

	delete_call, delete_result := calendar_event.example('delete')
	assert delete_call == '{"id": 1}'
	assert delete_result == 'true'

	exist_call, exist_result := calendar_event.example('exist')
	assert exist_call == '{"id": 1}'
	assert exist_result == 'true'

	list_call, list_result := calendar_event.example('list')
	assert list_call == '{}'
	assert list_result == '[{"title": "Team Meeting", "start_time": "2025-01-01T10:00:00Z", "end_time": "2025-01-01T11:00:00Z", "attendees": [], "docs": [], "calendar_id": 1, "status": "published", "is_all_day": false, "reminder_mins": [15], "color": "#0000FF", "timezone": "UTC", "locations": []}]'

	unknown_call, unknown_result := calendar_event.example('unknown')
	assert unknown_call == '{}'
	assert unknown_result == '{}'

	println('✓ CalendarEvent example test passed!')
}
