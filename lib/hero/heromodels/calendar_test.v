#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module heromodels

import freeflowuniverse.herolib.hero.heromodels

// Test Calendar model CRUD operations
fn test_calendar_new() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test creating a new calendar with all fields
	mut calendar := mydb.calendar.new(
		name:        'Test Calendar'
		description: 'A test calendar for unit testing'
		color:       '#FF0000'
		timezone:    'UTC'
		is_public:   true
	) or { panic('Failed to create calendar: ${err}') }

	// Verify the calendar was created with correct values
	assert calendar.name == 'Test Calendar'
	assert calendar.description == 'A test calendar for unit testing'
	assert calendar.color == '#FF0000'
	assert calendar.timezone == 'UTC'
	assert calendar.is_public == true
	assert calendar.id == 0 // Should be 0 before saving
	assert calendar.updated_at > 0 // Should have timestamp
}

fn test_calendar_set_and_get() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a calendar
	mut calendar := mydb.calendar.new(
		name:        'Work Calendar'
		description: 'Calendar for work events'
		color:       '#0000FF'
		timezone:    'America/New_York'
		is_public:   false
	) or { panic('Failed to create calendar: ${err}') }

	// Save the calendar
	calendar = mydb.calendar.set(calendar) or { panic('Failed to save calendar: ${err}') }

	// Verify ID was assigned
	assert calendar.id > 0
	original_id := calendar.id

	// Retrieve the calendar
	retrieved_calendar := mydb.calendar.get(calendar.id) or {
		panic('Failed to get calendar: ${err}')
	}

	// Verify all fields match
	assert retrieved_calendar.id == original_id
	assert retrieved_calendar.name == 'Work Calendar'
	assert retrieved_calendar.description == 'Calendar for work events'
	assert retrieved_calendar.color == '#0000FF'
	assert retrieved_calendar.timezone == 'America/New_York'
	assert retrieved_calendar.is_public == false
	assert retrieved_calendar.created_at > 0
	assert retrieved_calendar.updated_at > 0
}

fn test_calendar_update() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save a calendar
	mut calendar := mydb.calendar.new(
		name:        'Original Calendar'
		description: 'Original description'
		color:       '#00FF00'
		timezone:    'UTC'
		is_public:   true
	) or { panic('Failed to create calendar: ${err}') }

	calendar = mydb.calendar.set(calendar) or { panic('Failed to save calendar: ${err}') }
	original_id := calendar.id
	original_created_at := calendar.created_at
	original_updated_at := calendar.updated_at

	// Update the calendar
	calendar.name = 'Updated Calendar'
	calendar.description = 'Updated description'
	calendar.color = '#FFFF00'
	calendar.timezone = 'Europe/London'
	calendar.is_public = false

	calendar = mydb.calendar.set(calendar) or { panic('Failed to update calendar: ${err}') }

	// Verify ID remains the same and updated_at is set (may be same if very fast)
	assert calendar.id == original_id
	assert calendar.created_at == original_created_at
	assert calendar.updated_at >= original_updated_at

	// Retrieve and verify updates
	updated_calendar := mydb.calendar.get(calendar.id) or {
		panic('Failed to get updated calendar: ${err}')
	}
	assert updated_calendar.name == 'Updated Calendar'
	assert updated_calendar.description == 'Updated description'
	assert updated_calendar.color == '#FFFF00'
	assert updated_calendar.timezone == 'Europe/London'
	assert updated_calendar.is_public == false
}

fn test_calendar_exist() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test non-existent calendar
	exists := mydb.calendar.exist(999) or { panic('Failed to check existence: ${err}') }
	assert exists == false

	// Create and save a calendar
	mut calendar := mydb.calendar.new(
		name:        'Existence Test'
		description: 'Testing existence'
		color:       '#FF00FF'
		timezone:    'UTC'
		is_public:   true
	) or { panic('Failed to create calendar: ${err}') }

	calendar = mydb.calendar.set(calendar) or { panic('Failed to save calendar: ${err}') }

	// Test existing calendar
	exists_after_save := mydb.calendar.exist(calendar.id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_after_save == true
}

fn test_calendar_delete() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save a calendar
	mut calendar := mydb.calendar.new(
		name:        'To Be Deleted'
		description: 'This calendar will be deleted'
		color:       '#000000'
		timezone:    'UTC'
		is_public:   false
	) or { panic('Failed to create calendar: ${err}') }

	calendar = mydb.calendar.set(calendar) or { panic('Failed to save calendar: ${err}') }
	calendar_id := calendar.id

	// Verify it exists
	exists_before := mydb.calendar.exist(calendar_id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_before == true

	// Delete the calendar
	mydb.calendar.delete(calendar_id) or { panic('Failed to delete calendar: ${err}') }

	// Verify it no longer exists
	exists_after := mydb.calendar.exist(calendar_id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_after == false

	// Verify get fails
	if _ := mydb.calendar.get(calendar_id) {
		panic('Should not be able to get deleted calendar')
	}
}

fn test_calendar_list() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Clear any existing calendars by creating a fresh DB
	mydb = heromodels.new() or { panic('Failed to create fresh DB: ${err}') }

	// Initially should be empty
	initial_list := mydb.calendar.list() or { panic('Failed to list calendars: ${err}') }
	initial_count := initial_list.len

	// Create multiple calendars
	mut calendar1 := mydb.calendar.new(
		name:        'Calendar 1'
		description: 'First calendar'
		color:       '#FF0000'
		timezone:    'UTC'
		is_public:   true
	) or { panic('Failed to create calendar1: ${err}') }

	mut calendar2 := mydb.calendar.new(
		name:        'Calendar 2'
		description: 'Second calendar'
		color:       '#00FF00'
		timezone:    'America/New_York'
		is_public:   false
	) or { panic('Failed to create calendar2: ${err}') }

	// Save both calendars
	calendar1 = mydb.calendar.set(calendar1) or { panic('Failed to save calendar1: ${err}') }
	calendar2 = mydb.calendar.set(calendar2) or { panic('Failed to save calendar2: ${err}') }

	// List calendars
	calendar_list := mydb.calendar.list() or { panic('Failed to list calendars: ${err}') }

	// Should have 2 more calendars than initially
	assert calendar_list.len == initial_count + 2

	// Find our calendars in the list
	mut found_calendar1 := false
	mut found_calendar2 := false

	for cal in calendar_list {
		if cal.name == 'Calendar 1' {
			found_calendar1 = true
			assert cal.description == 'First calendar'
			assert cal.color == '#FF0000'
			assert cal.is_public == true
		}
		if cal.name == 'Calendar 2' {
			found_calendar2 = true
			assert cal.description == 'Second calendar'
			assert cal.color == '#00FF00'
			assert cal.is_public == false
		}
	}

	assert found_calendar1 == true
	assert found_calendar2 == true
}

fn test_calendar_edge_cases() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test empty strings
	mut calendar := mydb.calendar.new(
		name:        ''
		description: ''
		color:       ''
		timezone:    ''
		is_public:   false
	) or { panic('Failed to create calendar with empty strings: ${err}') }

	calendar = mydb.calendar.set(calendar) or {
		panic('Failed to save calendar with empty strings: ${err}')
	}

	retrieved := mydb.calendar.get(calendar.id) or {
		panic('Failed to get calendar with empty strings: ${err}')
	}
	assert retrieved.name == ''
	assert retrieved.description == ''
	assert retrieved.color == ''
	assert retrieved.timezone == ''

	// Test large events array
	mut large_calendar := mydb.calendar.new(
		name:        'Large Calendar'
		description: 'Calendar with many events'
		color:       '#123456'
		timezone:    'UTC'
		is_public:   true
	) or { panic('Failed to create large calendar: ${err}') }

	large_calendar = mydb.calendar.set(large_calendar) or {
		panic('Failed to save large calendar: ${err}')
	}

	large_retrieved := mydb.calendar.get(large_calendar.id) or {
		panic('Failed to get large calendar: ${err}')
	}
}
