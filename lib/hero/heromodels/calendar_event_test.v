#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module heromodels

import freeflowuniverse.herolib.hero.heromodels

// Test CalendarEvent model CRUD operations
fn test_calendar_event_new() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test creating a new calendar event with all fields
	mut event := mydb.calendar_event.new(
		name:           'Test Event'
		description:    'A test calendar event for unit testing'
		title:          'Team Meeting'
		start_time:     '2024-01-15 10:00:00'
		end_time:       '2024-01-15 11:00:00'
		location:       'Conference Room A'
		attendees:      [u32(1), 2, 3]
		fs_items:       [u32(10), 20]
		calendar_id:    1
		status:         .published
		is_all_day:     false
		is_recurring:   false
		recurrence:     []
		reminder_mins:  [15, 30]
		color:          '#FF0000'
		timezone:       'UTC'
		securitypolicy: 1
		tags:           ['meeting', 'team']
		comments:       []
	) or { panic('Failed to create calendar event: ${err}') }

	// Verify the event was created with correct values
	assert event.name == 'Test Event'
	assert event.description == 'A test calendar event for unit testing'
	assert event.title == 'Team Meeting'
	assert event.location == 'Conference Room A'
	assert event.attendees.len == 3
	assert event.attendees[0] == 1
	assert event.fs_items.len == 2
	assert event.fs_items[0] == 10
	assert event.calendar_id == 1
	assert event.status == .published
	assert event.is_all_day == false
	assert event.is_recurring == false
	assert event.reminder_mins.len == 2
	assert event.reminder_mins[0] == 15
	assert event.color == '#FF0000'
	assert event.timezone == 'UTC'
	assert event.id == 0 // Should be 0 before saving
	assert event.start_time > 0 // Should have Unix timestamp
	assert event.end_time > event.start_time
	assert event.updated_at > 0
}

fn test_calendar_event_set_and_get() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a calendar event
	mut event := mydb.calendar_event.new(
		name:           'Work Event'
		description:    'Important work meeting'
		title:          'Project Review'
		start_time:     '2024-02-20 14:00:00'
		end_time:       '2024-02-20 16:00:00'
		location:       'Office Building'
		attendees:      [u32(5), 6, 7, 8]
		fs_items:       [u32(100)]
		calendar_id:    2
		status:         .draft
		is_all_day:     false
		is_recurring:   true
		recurrence:     [
			RecurrenceRule{
				frequency:   .weekly
				interval:    1
				until:       0
				count:       10
				by_weekday:  [1, 3, 5] // Monday, Wednesday, Friday
				by_monthday: []
			},
		]
		reminder_mins:  [5, 15, 60]
		color:          '#00FF00'
		timezone:       'America/New_York'
		securitypolicy: 2
		tags:           ['work', 'project', 'review']
		comments:       []
	) or { panic('Failed to create calendar event: ${err}') }

	// Save the event
	mydb.calendar_event.set(mut event) or { panic('Failed to save calendar event: ${err}') }

	// Verify ID was assigned
	assert event.id > 0
	original_id := event.id

	// Retrieve the event
	retrieved_event := mydb.calendar_event.get(event.id) or {
		panic('Failed to get calendar event: ${err}')
	}

	// Verify all fields match
	assert retrieved_event.id == original_id
	assert retrieved_event.name == 'Work Event'
	assert retrieved_event.description == 'Important work meeting'
	assert retrieved_event.title == 'Project Review'
	assert retrieved_event.location == 'Office Building'
	assert retrieved_event.attendees.len == 4
	assert retrieved_event.attendees[0] == 5
	assert retrieved_event.fs_items.len == 1
	assert retrieved_event.fs_items[0] == 100
	assert retrieved_event.calendar_id == 2
	assert retrieved_event.status == .draft
	assert retrieved_event.is_all_day == false
	assert retrieved_event.is_recurring == true
	assert retrieved_event.recurrence.len == 1
	assert retrieved_event.recurrence[0].frequency == .weekly
	assert retrieved_event.recurrence[0].interval == 1
	assert retrieved_event.recurrence[0].count == 10
	assert retrieved_event.recurrence[0].by_weekday.len == 3
	assert retrieved_event.reminder_mins.len == 3
	assert retrieved_event.reminder_mins[0] == 5
	assert retrieved_event.color == '#00FF00'
	assert retrieved_event.timezone == 'America/New_York'
	assert retrieved_event.created_at > 0
	assert retrieved_event.updated_at > 0
}

fn test_calendar_event_update() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save an event
	mut event := mydb.calendar_event.new(
		name:           'Original Event'
		description:    'Original description'
		title:          'Original Title'
		start_time:     '2024-03-10 09:00:00'
		end_time:       '2024-03-10 10:00:00'
		location:       'Room 1'
		attendees:      [u32(1)]
		fs_items:       []u32{}
		calendar_id:    1
		status:         .draft
		is_all_day:     false
		is_recurring:   false
		recurrence:     []
		reminder_mins:  [10]
		color:          '#0000FF'
		timezone:       'UTC'
		securitypolicy: 1
		tags:           ['original']
		comments:       []
	) or { panic('Failed to create calendar event: ${err}') }

	mydb.calendar_event.set(mut event) or { panic('Failed to save calendar event: ${err}') }
	original_id := event.id
	original_created_at := event.created_at
	original_updated_at := event.updated_at

	// Update the event
	event.name = 'Updated Event'
	event.description = 'Updated description'
	event.title = 'Updated Title'
	event.location = 'Room 2'
	event.attendees = [u32(1), 2, 3]
	event.fs_items = [u32(50), 60]
	event.calendar_id = 2
	event.status = .published
	event.is_all_day = true
	event.is_recurring = true
	event.recurrence = [
		RecurrenceRule{
			frequency:   .daily
			interval:    2
			until:       0
			count:       5
			by_weekday:  []
			by_monthday: []
		},
	]
	event.reminder_mins = [5, 30, 120]
	event.color = '#FFFF00'
	event.timezone = 'Europe/London'

	mydb.calendar_event.set(mut event) or { panic('Failed to update calendar event: ${err}') }

	// Verify ID remains the same and updated_at is set
	assert event.id == original_id
	assert event.created_at == original_created_at
	assert event.updated_at >= original_updated_at

	// Retrieve and verify updates
	updated_event := mydb.calendar_event.get(event.id) or {
		panic('Failed to get updated calendar event: ${err}')
	}
	assert updated_event.name == 'Updated Event'
	assert updated_event.description == 'Updated description'
	assert updated_event.title == 'Updated Title'
	assert updated_event.location == 'Room 2'
	assert updated_event.attendees.len == 3
	assert updated_event.fs_items.len == 2
	assert updated_event.calendar_id == 2
	assert updated_event.status == .published
	assert updated_event.is_all_day == true
	assert updated_event.is_recurring == true
	assert updated_event.recurrence.len == 1
	assert updated_event.recurrence[0].frequency == .daily
	assert updated_event.recurrence[0].interval == 2
	assert updated_event.reminder_mins.len == 3
	assert updated_event.color == '#FFFF00'
	assert updated_event.timezone == 'Europe/London'
}

fn test_calendar_event_exist() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test non-existent event
	exists := mydb.calendar_event.exist(999) or { panic('Failed to check existence: ${err}') }
	assert exists == false

	// Create and save an event
	mut event := mydb.calendar_event.new(
		name:           'Existence Test'
		description:    'Testing existence'
		title:          'Test Event'
		start_time:     '2024-04-01 12:00:00'
		end_time:       '2024-04-01 13:00:00'
		location:       'Test Location'
		attendees:      []u32{}
		fs_items:       []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     false
		is_recurring:   false
		recurrence:     []
		reminder_mins:  []
		color:          '#FF00FF'
		timezone:       'UTC'
		securitypolicy: 1
		tags:           ['test']
		comments:       []
	) or { panic('Failed to create calendar event: ${err}') }

	mydb.calendar_event.set(mut event) or { panic('Failed to save calendar event: ${err}') }

	// Test existing event
	exists_after_save := mydb.calendar_event.exist(event.id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_after_save == true
}

fn test_calendar_event_delete() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save an event
	mut event := mydb.calendar_event.new(
		name:           'To Be Deleted'
		description:    'This event will be deleted'
		title:          'Delete Me'
		start_time:     '2024-05-01 08:00:00'
		end_time:       '2024-05-01 09:00:00'
		location:       'Nowhere'
		attendees:      []u32{}
		fs_items:       []u32{}
		calendar_id:    1
		status:         .cancelled
		is_all_day:     false
		is_recurring:   false
		recurrence:     []
		reminder_mins:  []
		color:          '#000000'
		timezone:       'UTC'
		securitypolicy: 1
		tags:           []
		comments:       []
	) or { panic('Failed to create calendar event: ${err}') }

	mydb.calendar_event.set(mut event) or { panic('Failed to save calendar event: ${err}') }
	event_id := event.id

	// Verify it exists
	exists_before := mydb.calendar_event.exist(event_id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_before == true

	// Delete the event
	mydb.calendar_event.delete(event_id) or { panic('Failed to delete calendar event: ${err}') }

	// Verify it no longer exists
	exists_after := mydb.calendar_event.exist(event_id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_after == false

	// Verify get fails
	if _ := mydb.calendar_event.get(event_id) {
		panic('Should not be able to get deleted calendar event')
	}
}

fn test_calendar_event_list() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Clear any existing events by creating a fresh DB
	mydb = heromodels.new() or { panic('Failed to create fresh DB: ${err}') }

	// Initially should be empty
	initial_list := mydb.calendar_event.list() or {
		panic('Failed to list calendar events: ${err}')
	}
	initial_count := initial_list.len

	// Create multiple events
	mut event1 := mydb.calendar_event.new(
		name:           'Event 1'
		description:    'First event'
		title:          'Morning Meeting'
		start_time:     '2024-06-01 09:00:00'
		end_time:       '2024-06-01 10:00:00'
		location:       'Room A'
		attendees:      [u32(1)]
		fs_items:       []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     false
		is_recurring:   false
		recurrence:     []
		reminder_mins:  [15]
		color:          '#FF0000'
		timezone:       'UTC'
		securitypolicy: 1
		tags:           ['morning']
		comments:       []
	) or { panic('Failed to create event1: ${err}') }

	mut event2 := mydb.calendar_event.new(
		name:           'Event 2'
		description:    'Second event'
		title:          'Afternoon Workshop'
		start_time:     '2024-06-01 14:00:00'
		end_time:       '2024-06-01 17:00:00'
		location:       'Room B'
		attendees:      [u32(2), 3]
		fs_items:       [u32(1), 2, 3]
		calendar_id:    2
		status:         .draft
		is_all_day:     false
		is_recurring:   true
		recurrence:     [
			RecurrenceRule{
				frequency:   .monthly
				interval:    1
				until:       0
				count:       12
				by_weekday:  []
				by_monthday: [1]
			},
		]
		reminder_mins:  [30, 60]
		color:          '#00FF00'
		timezone:       'America/New_York'
		securitypolicy: 2
		tags:           ['workshop', 'afternoon']
		comments:       []
	) or { panic('Failed to create event2: ${err}') }

	// Save both events
	mydb.calendar_event.set(mut event1) or { panic('Failed to save event1: ${err}') }
	mydb.calendar_event.set(mut event2) or { panic('Failed to save event2: ${err}') }

	// List events
	event_list := mydb.calendar_event.list() or { panic('Failed to list calendar events: ${err}') }

	// Should have 2 more events than initially
	assert event_list.len == initial_count + 2

	// Find our events in the list
	mut found_event1 := false
	mut found_event2 := false

	for evt in event_list {
		if evt.name == 'Event 1' {
			found_event1 = true
			assert evt.title == 'Morning Meeting'
			assert evt.location == 'Room A'
			assert evt.status == .published
			assert evt.is_recurring == false
		}
		if evt.name == 'Event 2' {
			found_event2 = true
			assert evt.title == 'Afternoon Workshop'
			assert evt.location == 'Room B'
			assert evt.status == .draft
			assert evt.is_recurring == true
			assert evt.recurrence.len == 1
			assert evt.recurrence[0].frequency == .monthly
		}
	}

	assert found_event1 == true
	assert found_event2 == true
}

fn test_calendar_event_edge_cases() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test empty strings and minimal data
	mut event := mydb.calendar_event.new(
		name:           ''
		description:    ''
		title:          ''
		start_time:     '2024-01-01 00:00:00'
		end_time:       '2024-01-01 00:01:00'
		location:       ''
		attendees:      []u32{}
		fs_items:       []u32{}
		calendar_id:    0
		status:         .draft
		is_all_day:     false
		is_recurring:   false
		recurrence:     []
		reminder_mins:  []
		color:          ''
		timezone:       ''
		securitypolicy: 0
		tags:           []
		comments:       []
	) or { panic('Failed to create event with empty strings: ${err}') }

	mydb.calendar_event.set(mut event) or {
		panic('Failed to save event with empty strings: ${err}')
	}

	retrieved := mydb.calendar_event.get(event.id) or {
		panic('Failed to get event with empty strings: ${err}')
	}
	assert retrieved.name == ''
	assert retrieved.description == ''
	assert retrieved.title == ''
	assert retrieved.location == ''
	assert retrieved.color == ''
	assert retrieved.timezone == ''
	assert retrieved.attendees.len == 0
	assert retrieved.fs_items.len == 0
	assert retrieved.reminder_mins.len == 0

	// Test all-day event
	mut all_day_event := mydb.calendar_event.new(
		name:           'All Day Event'
		description:    'This is an all-day event'
		title:          'Holiday'
		start_time:     '2024-12-25 00:00:00'
		end_time:       '2024-12-25 23:59:59'
		location:       'Everywhere'
		attendees:      []u32{}
		fs_items:       []u32{}
		calendar_id:    1
		status:         .published
		is_all_day:     true
		is_recurring:   false
		recurrence:     []
		reminder_mins:  []
		color:          '#FF0000'
		timezone:       'UTC'
		securitypolicy: 1
		tags:           ['holiday']
		comments:       []
	) or { panic('Failed to create all-day event: ${err}') }

	mydb.calendar_event.set(mut all_day_event) or { panic('Failed to save all-day event: ${err}') }

	all_day_retrieved := mydb.calendar_event.get(all_day_event.id) or {
		panic('Failed to get all-day event: ${err}')
	}
	assert all_day_retrieved.is_all_day == true
	assert all_day_retrieved.title == 'Holiday'

	// Test complex recurring event
	mut complex_event := mydb.calendar_event.new(
		name:           'Complex Recurring Event'
		description:    'Event with complex recurrence rules'
		title:          'Weekly Team Standup'
		start_time:     '2024-01-01 10:00:00'
		end_time:       '2024-01-01 10:30:00'
		location:       'Conference Room'
		attendees:      []u32{len: 50, init: u32(index + 1)}   // 50 attendees
		fs_items:       []u32{len: 20, init: u32(index + 100)} // 20 files
		calendar_id:    1
		status:         .published
		is_all_day:     false
		is_recurring:   true
		recurrence:     [
			RecurrenceRule{
				frequency:   .weekly
				interval:    1
				until:       0
				count:       52              // One year
				by_weekday:  [1, 2, 3, 4, 5] // Weekdays
				by_monthday: []
			},
			RecurrenceRule{
				frequency:   .monthly
				interval:    1
				until:       0
				count:       12
				by_weekday:  []
				by_monthday: [1, 15] // 1st and 15th of month
			},
		]
		reminder_mins:  [5, 15, 30, 60, 120, 1440] // Multiple reminders
		color:          '#123456'
		timezone:       'America/Los_Angeles'
		securitypolicy: 3
		tags:           ['standup', 'team', 'recurring', 'important']
		comments:       []
	) or { panic('Failed to create complex event: ${err}') }

	mydb.calendar_event.set(mut complex_event) or { panic('Failed to save complex event: ${err}') }

	complex_retrieved := mydb.calendar_event.get(complex_event.id) or {
		panic('Failed to get complex event: ${err}')
	}
	assert complex_retrieved.attendees.len == 50
	assert complex_retrieved.fs_items.len == 20
	assert complex_retrieved.recurrence.len == 2
	assert complex_retrieved.recurrence[0].frequency == .weekly
	assert complex_retrieved.recurrence[1].frequency == .monthly
	assert complex_retrieved.recurrence[0].by_weekday.len == 5
	assert complex_retrieved.recurrence[1].by_monthday.len == 2
	assert complex_retrieved.reminder_mins.len == 6
	assert complex_retrieved.reminder_mins[0] == 5
	assert complex_retrieved.reminder_mins[5] == 1440
}
