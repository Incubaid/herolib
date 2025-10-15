module vfs_calendar

import incubaid.herolib.circles.mcc.models as calendar
import incubaid.herolib.circles.mcc.db as core
import incubaid.herolib.data.ourtime
import incubaid.herolib.circles.base
import json

// get_sample_events provides a set of test events
fn get_sample_events() ![]calendar.CalendarEvent {
	return [
		calendar.CalendarEvent{
			id:         1
			title:      'Meeting'
			start_time: ourtime.new('2023-10-05 14:00:00')!
			organizer:  'Alice'
		},
		calendar.CalendarEvent{
			id:         2
			title:      'Conference'
			start_time: ourtime.new('2023-10-15 09:00:00')!
			organizer:  'Bob'
		},
		calendar.CalendarEvent{
			id:         3
			title:      'Webinar'
			start_time: ourtime.new('2023-11-01 10:00:00')!
			organizer:  '' // No organizer
		},
	]
}

// Helper function to create a test VFS instance
fn test_calendar_vfs() ! {
	// Create a session state
	mut session_state := base.new_session(name: 'test')!

	// Setup mock database
	mut calendar_db := core.new_calendardb(session_state)!

	events := get_sample_events() or { return error('Failed to get sample events: ${err}') }
	for event in events {
		calendar_db.set(event)!
	}

	mut calendar_vfs := new(&calendar_db) or { panic(err) }

	// Test root directory
	root := calendar_vfs.root_get()!
	assert root.is_dir()

	// Test Root directory listing
	mut entries := calendar_vfs.dir_list('')!
	assert entries.len == 3 // Three unique calendar IDs: "1", "2", "3"

	mut names := entries.map((it as CalendarFSEntry).metadata.name)

	assert names.contains('1')
	assert names.contains('2')
	assert names.contains('3')
	for entry in entries {
		assert entry.is_dir()
	}

	// Test Calendar directory listing
	entries = calendar_vfs.dir_list('1')!
	assert entries.len == 3

	names = entries.map((it as CalendarFSEntry).metadata.name)
	assert 'by_date' in names
	assert 'by_title' in names
	assert 'by_organizer' in names
	for entry in entries {
		assert entry.is_dir()
	}

	// Test by_date directory listing
	entries = calendar_vfs.dir_list('1/by_date')!
	assert entries.len == 1 // Only October 2023 for calendar "1"
	names = entries.map((it as CalendarFSEntry).metadata.name)
	assert '2023_10' in names
	for entry in entries {
		assert entry.is_dir()
	}

	// Test YYYY_MM directory listing
	entries = calendar_vfs.dir_list('1/by_date/2023_10')!
	assert entries.len == 1 // One event in October for calendar "1"

	names = entries.map((it as CalendarFSEntry).metadata.name)
	assert '05_meeting.json' in names // texttools.name_fix converts "Meeting" to lowercase
	for entry in entries {
		assert entry.is_file()
	}

	// Test by_title directory listing
	entries = calendar_vfs.dir_list('1/by_title')!
	assert entries.len == 1 // One event in calendar "1"
	names = entries.map((it as CalendarFSEntry).metadata.name)
	assert 'meeting.json' in names
	for entry in entries {
		assert entry.is_file()
	}

	// Test by_organizer directory listing
	entries = calendar_vfs.dir_list('1/by_organizer')!
	assert entries.len == 1 // One event with an organizer in calendar "1"
	names = entries.map((it as CalendarFSEntry).metadata.name)
	assert 'alice.json' in names
	for entry in entries {
		assert entry.is_file()
	}

	// Test File reading
	data := calendar_vfs.file_read('1/by_date/2023_10/05_meeting.json')!
	event := json.decode(calendar.CalendarEvent, data.bytestr())!
	assert event.id == 1
	assert event.title == 'Meeting'
	assert event.organizer == 'Alice'
	assert event.start_time.str() == '2023-10-05 14:00'

	// Test Existence checks
	assert calendar_vfs.exists('') // Root
	assert calendar_vfs.exists('1') // Calendar
	assert calendar_vfs.exists('1/by_date') // Browsing method
	assert calendar_vfs.exists('1/by_date/2023_10') // Year_month
	assert calendar_vfs.exists('1/by_date/2023_10/05_meeting.json') // Event file
	assert calendar_vfs.exists('1/by_title/meeting.json')
	assert calendar_vfs.exists('1/by_organizer/alice.json')
	assert !calendar_vfs.exists('non_existent')
	assert !calendar_vfs.exists('1/invalid_method')

	// File metadata
	file_entry := calendar_vfs.get('1/by_date/2023_10/05_meeting.json')!
	assert file_entry.is_file()
	assert (file_entry as CalendarFSEntry).metadata.name == '05_meeting.json'
	assert (file_entry as CalendarFSEntry).metadata.size > 0

	// Directory metadata
	dir_entry := calendar_vfs.get('1/by_date')!
	assert (dir_entry as CalendarFSEntry).is_dir()
	assert (dir_entry as CalendarFSEntry).metadata.name == 'by_date'
}
