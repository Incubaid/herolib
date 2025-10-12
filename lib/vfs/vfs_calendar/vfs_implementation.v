module vfs_calendar

import json
import time
import incubaid.herolib.vfs
import incubaid.herolib.circles.mcc.models as calendar
import incubaid.herolib.core.texttools

// Basic operations
pub fn (mut myvfs CalendarVFS) root_get() !vfs.FSEntry {
	metadata := vfs.Metadata{
		id:          1
		name:        ''
		file_type:   .directory
		created_at:  time.now().unix()
		modified_at: time.now().unix()
		accessed_at: time.now().unix()
	}

	return CalendarFSEntry{
		path:     ''
		metadata: metadata
	}
}

// File operations
pub fn (mut myvfs CalendarVFS) file_create(path string) !vfs.FSEntry {
	return error('Calendar VFS is read-only')
}

pub fn (mut myvfs CalendarVFS) file_read(path string) ![]u8 {
	if !myvfs.exists(path) {
		return error('File does not exist: ${path}')
	}

	entry := myvfs.get(path)!

	if !entry.is_file() {
		return error('Path is not a file: ${path}')
	}

	calendar_entry := entry as CalendarFSEntry
	if event := calendar_entry.calendar {
		return json.encode(event).bytes()
	}

	return error('Failed to read file: ${path}')
}

pub fn (mut myvfs CalendarVFS) file_write(path string, data []u8) ! {
	return error('Calendar VFS is read-only')
}

pub fn (mut myvfs CalendarVFS) file_concatenate(path string, data []u8) ! {
	return error('Calendar VFS is read-only')
}

pub fn (mut myvfs CalendarVFS) file_delete(path string) ! {
	return error('Calendar VFS is read-only')
}

// Directory operations
pub fn (mut myvfs CalendarVFS) dir_create(path string) !vfs.FSEntry {
	return error('Calendar VFS is read-only')
}

pub fn (mut myvfs CalendarVFS) dir_list(path string) ![]vfs.FSEntry {
	if !myvfs.exists(path) {
		return error('Directory does not exist: ${path}')
	}

	// Get all events
	events := myvfs.calendar_db.getall() or { return error('Failed to get events: ${err}') }

	// If we're at the root, return all calendars
	if path == '' {
		return myvfs.list_calendars(events)!
	}

	// Split the path to determine the level
	path_parts := path.split('/')

	// Level 1: We're in a calendar, show the browsing methods (by_date, by_title, by_organizer)
	if path_parts.len == 1 {
		return myvfs.list_calendar_subdirs(path)!
	}

	// Level 2: We're in a browsing method directory
	if path_parts.len == 2 {
		match path_parts[1] {
			'by_date' {
				return myvfs.list_date_subdirs(path_parts[0], events)!
			}
			'by_title', 'by_organizer' {
				return myvfs.list_events_by_type(path_parts[0], path_parts[1], events)!
			}
			else {
				return error('Invalid browsing method: ${path_parts[1]}. Supported methods are by_date, by_title, by_organizer')
			}
		}
	}

	// Level 3: We're in a year_month directory under by_date
	if path_parts.len == 3 && path_parts[1] == 'by_date' {
		return myvfs.list_events_by_date(path_parts[0], path_parts[2], events)!
	}

	return error('Path depth not supported: ${path}')
}

pub fn (mut myvfs CalendarVFS) dir_delete(path string) ! {
	return error('Calendar VFS is read-only')
}

// Symlink operations
pub fn (mut myvfs CalendarVFS) link_create(target_path string, link_path string) !vfs.FSEntry {
	return error('Calendar VFS does not support symlinks')
}

pub fn (mut myvfs CalendarVFS) link_read(path string) !string {
	return error('Calendar VFS does not support symlinks')
}

pub fn (mut myvfs CalendarVFS) link_delete(path string) ! {
	return error('Calendar VFS does not support symlinks')
}

// Common operations
pub fn (mut myvfs CalendarVFS) exists(path string) bool {
	// Root always exists
	if path == '' {
		return true
	}

	// Get all events
	events := myvfs.calendar_db.getall() or { return false }

	path_parts := path.split('/')

	// Level 1: Check if the path is a calendar
	if path_parts.len == 1 {
		for event in events {
			if event.id.str() == path_parts[0] {
				return true
			}
		}
		return false
	}

	// Level 2: Check if the path is a valid browsing method
	if path_parts.len == 2 {
		if path_parts[1] !in ['by_date', 'by_title', 'by_organizer'] {
			return false
		}
		for event in events {
			if event.id.str() == path_parts[0] {
				return true
			}
		}
		return false
	}

	// Level 3: Check if the path is a valid year_month directory under by_date
	if path_parts.len == 3 && path_parts[1] == 'by_date' {
		for event in events {
			if event.id.str() != path_parts[0] {
				continue
			}
			event_time := event.start_time.time()
			year_month := '${event_time.year:04d}_${event_time.month:02d}'
			if year_month == path_parts[2] {
				return true
			}
		}
		return false
	}

	// Level 3 or 4: Check if the path is an event file
	if (path_parts.len == 4 && path_parts[1] == 'by_date')
		|| (path_parts.len == 3 && path_parts[1] in ['by_title', 'by_organizer']) {
		for event in events {
			if event.id.str() != path_parts[0] {
				continue
			}

			if path_parts[1] == 'by_date' {
				event_time := event.start_time.time()
				year_month := '${event_time.year:04d}_${event_time.month:02d}'
				day := '${event_time.day:02d}'
				filename := texttools.name_fix('${day}_${event.title}') + '.json'
				if year_month == path_parts[2] && filename == path_parts[3] {
					return true
				}
			} else if path_parts[1] == 'by_title' {
				filename := texttools.name_fix(event.title) + '.json'
				if filename == path_parts[2] {
					return true
				}
			} else if path_parts[1] == 'by_organizer' {
				if event.organizer.len > 0 {
					filename := texttools.name_fix(event.organizer) + '.json'
					if filename == path_parts[2] {
						return true
					}
				}
			}
		}
	}

	return false
}

pub fn (mut myvfs CalendarVFS) get(path string) !vfs.FSEntry {
	// Root always exists
	if path == '' {
		return myvfs.root_get()!
	}

	// Get all events
	events := myvfs.calendar_db.getall() or { return error('Failed to get events: ${err}') }

	path_parts := path.split('/')

	// Level 1: Check if the path is a calendar
	if path_parts.len == 1 {
		for event in events {
			if event.id.str() == path_parts[0] {
				metadata := vfs.Metadata{
					id:          u32(path_parts[0].bytes().bytestr().hash())
					name:        path_parts[0]
					file_type:   .directory
					created_at:  time.now().unix()
					modified_at: time.now().unix()
					accessed_at: time.now().unix()
				}
				return CalendarFSEntry{
					path:     path
					metadata: metadata
				}
			}
		}
		return error('Calendar not found: ${path_parts[0]}')
	}

	// Level 2: Check if the path is a browsing method directory
	if path_parts.len == 2 {
		if path_parts[1] !in ['by_date', 'by_title', 'by_organizer'] {
			return error('Invalid browsing method: ${path_parts[1]}. Supported methods are by_date, by_title, by_organizer')
		}
		for event in events {
			if event.id.str() == path_parts[0] {
				metadata := vfs.Metadata{
					id:          u32(path.bytes().bytestr().hash())
					name:        path_parts[1]
					file_type:   .directory
					created_at:  time.now().unix()
					modified_at: time.now().unix()
					accessed_at: time.now().unix()
				}
				return CalendarFSEntry{
					path:     path
					metadata: metadata
				}
			}
		}
		return error('Calendar not found: ${path_parts[0]}')
	}

	// Level 3: Check if the path is a year_month directory under by_date
	if path_parts.len == 3 && path_parts[1] == 'by_date' {
		for event in events {
			if event.id.str() != path_parts[0] {
				continue
			}
			event_time := event.start_time.time()
			year_month := '${event_time.year:04d}_${event_time.month:02d}'

			if year_month == path_parts[2] {
				metadata := vfs.Metadata{
					id:          u32(path.bytes().bytestr().hash())
					name:        path_parts[2]
					file_type:   .directory
					created_at:  time.now().unix()
					modified_at: time.now().unix()
					accessed_at: time.now().unix()
				}
				return CalendarFSEntry{
					path:     path
					metadata: metadata
				}
			}
		}
		return error('Date directory not found: ${path}')
	}

	// Level 3 or 4: Check if the path is an event file
	if (path_parts.len == 4 && path_parts[1] == 'by_date')
		|| (path_parts.len == 3 && path_parts[1] in ['by_title', 'by_organizer']) {
		for event in events {
			if event.id.str() != path_parts[0] {
				continue
			}

			if path_parts[1] == 'by_date' {
				event_time := event.start_time.time()
				year_month := '${event_time.year:04d}_${event_time.month:02d}'
				day := '${event_time.day:02d}'
				filename := texttools.name_fix('${day}_${event.title}') + '.json'
				if year_month == path_parts[2] && filename == path_parts[3] {
					metadata := vfs.Metadata{
						id:          u32(event.id)
						name:        filename
						file_type:   .file
						size:        u64(json.encode(event).len)
						created_at:  event.start_time.time().unix()
						modified_at: event.start_time.time().unix()
						accessed_at: time.now().unix()
					}
					return CalendarFSEntry{
						path:     path
						metadata: metadata
						calendar: event
					}
				}
			} else if path_parts[1] == 'by_title' {
				filename := texttools.name_fix(event.title) + '.json'
				if filename == path_parts[2] {
					metadata := vfs.Metadata{
						id:          u32(event.id)
						name:        filename
						file_type:   .file
						size:        u64(json.encode(event).len)
						created_at:  event.start_time.time().unix()
						modified_at: event.start_time.time().unix()
						accessed_at: time.now().unix()
					}
					return CalendarFSEntry{
						path:     path
						metadata: metadata
						calendar: event
					}
				}
			} else if path_parts[1] == 'by_organizer' {
				if event.organizer.len > 0 {
					filename := texttools.name_fix(event.organizer) + '.json'
					if filename == path_parts[2] {
						metadata := vfs.Metadata{
							id:          u32(event.id)
							name:        filename
							file_type:   .file
							size:        u64(json.encode(event).len)
							created_at:  event.start_time.time().unix()
							modified_at: event.start_time.time().unix()
							accessed_at: time.now().unix()
						}
						return CalendarFSEntry{
							path:     path
							metadata: metadata
							calendar: event
						}
					}
				}
			}
		}
		return error('Event file not found: ${path}')
	}

	return error('Path not found: ${path}')
}

pub fn (mut myvfs CalendarVFS) rename(old_path string, new_path string) !vfs.FSEntry {
	return error('Calendar VFS is read-only')
}

pub fn (mut myvfs CalendarVFS) copy(src_path string, dst_path string) !vfs.FSEntry {
	return error('Calendar VFS is read-only')
}

pub fn (mut myvfs CalendarVFS) move(src_path string, dst_path string) !vfs.FSEntry {
	return error('Calendar VFS is read-only')
}

pub fn (mut myvfs CalendarVFS) delete(path string) ! {
	return error('Calendar VFS is read-only')
}

// FSEntry Operations
pub fn (mut myvfs CalendarVFS) get_path(entry &vfs.FSEntry) !string {
	calendar_entry := entry as CalendarFSEntry
	return calendar_entry.path
}

pub fn (mut myvfs CalendarVFS) print() ! {
	println('Calendar VFS')
}

// Cleanup operation
pub fn (mut myvfs CalendarVFS) destroy() ! {
	// Nothing to clean up
}

// Helper functions

// list_calendars lists all unique calendars as directories
fn (mut myvfs CalendarVFS) list_calendars(events []calendar.CalendarEvent) ![]vfs.FSEntry {
	mut calendars := map[string]bool{}

	// Collect unique calendar names
	for event in events {
		calendars[event.id.str()] = true
	}

	// Create FSEntry for each calendar
	mut result := []vfs.FSEntry{cap: calendars.len}
	for calendar, _ in calendars {
		metadata := vfs.Metadata{
			id:          u32(calendar.bytes().bytestr().hash())
			name:        calendar
			file_type:   .directory
			created_at:  time.now().unix()
			modified_at: time.now().unix()
			accessed_at: time.now().unix()
		}
		result << CalendarFSEntry{
			path:     calendar
			metadata: metadata
		}
	}

	return result
}

// list_calendar_subdirs lists the browsing methods (by_date, by_title, by_organizer) for a calendar
fn (mut myvfs CalendarVFS) list_calendar_subdirs(calendar_ string) ![]vfs.FSEntry {
	mut result := []vfs.FSEntry{cap: 3}

	// Create by_date directory
	by_date_metadata := vfs.Metadata{
		id:          u32('${calendar_}/by_date'.bytes().bytestr().hash())
		name:        'by_date'
		file_type:   .directory
		created_at:  time.now().unix()
		modified_at: time.now().unix()
		accessed_at: time.now().unix()
	}
	result << CalendarFSEntry{
		path:     '${calendar_}/by_date'
		metadata: by_date_metadata
	}

	// Create by_title directory
	by_title_metadata := vfs.Metadata{
		id:          u32('${calendar_}/by_title'.bytes().bytestr().hash())
		name:        'by_title'
		file_type:   .directory
		created_at:  time.now().unix()
		modified_at: time.now().unix()
		accessed_at: time.now().unix()
	}
	result << CalendarFSEntry{
		path:     '${calendar_}/by_title'
		metadata: by_title_metadata
	}

	// Create by_organizer directory
	by_organizer_metadata := vfs.Metadata{
		id:          u32('${calendar_}/by_organizer'.bytes().bytestr().hash())
		name:        'by_organizer'
		file_type:   .directory
		created_at:  time.now().unix()
		modified_at: time.now().unix()
		accessed_at: time.now().unix()
	}
	result << CalendarFSEntry{
		path:     '${calendar_}/by_organizer'
		metadata: by_organizer_metadata
	}

	return result
}

// list_date_subdirs lists year_month directories under by_date for a calendar
fn (mut myvfs CalendarVFS) list_date_subdirs(calendar_ string, events []calendar.CalendarEvent) ![]vfs.FSEntry {
	mut date_dirs := map[string]bool{}

	// Collect unique year_month directories
	for event in events {
		if event.id.str() != calendar_ {
			continue
		}
		event_time := event.start_time.time()
		year_month := '${event_time.year:04d}_${event_time.month:02d}'
		date_dirs[year_month] = true
	}

	// Create FSEntry for each year_month directory
	mut result := []vfs.FSEntry{cap: date_dirs.len}
	for year_month, _ in date_dirs {
		metadata := vfs.Metadata{
			id:          u32('${calendar_}/by_date/${year_month}'.bytes().bytestr().hash())
			name:        year_month
			file_type:   .directory
			created_at:  time.now().unix()
			modified_at: time.now().unix()
			accessed_at: time.now().unix()
		}
		result << CalendarFSEntry{
			path:     '${calendar_}/by_date/${year_month}'
			metadata: metadata
		}
	}

	return result
}

// list_events_by_date lists events in a specific year_month directory
fn (mut myvfs CalendarVFS) list_events_by_date(calendar_ string, year_month string, events []calendar.CalendarEvent) ![]vfs.FSEntry {
	mut result := []vfs.FSEntry{}

	for event in events {
		if event.id.str() != calendar_ {
			continue
		}

		event_time := event.start_time.time()
		event_year_month := '${event_time.year:04d}_${event_time.month:02d}'
		if event_year_month != year_month {
			continue
		}

		day := '${event_time.day:02d}'
		filename := texttools.name_fix('${day}_${event.title}') + '.json'
		metadata := vfs.Metadata{
			id:          u32(event.id)
			name:        filename
			file_type:   .file
			size:        u64(json.encode(event).len)
			created_at:  event.start_time.time().unix()
			modified_at: event.start_time.time().unix()
			accessed_at: time.now().unix()
		}
		result << CalendarFSEntry{
			path:     '${calendar_}/by_date/${year_month}/${filename}'
			metadata: metadata
			calendar: event
		}
	}

	return result
}

// list_events_by_type lists events by a specific browsing method (by_title or by_organizer)
fn (mut myvfs CalendarVFS) list_events_by_type(calendar_ string, list_type string, events []calendar.CalendarEvent) ![]vfs.FSEntry {
	mut result := []vfs.FSEntry{}

	for event in events {
		if event.id.str() != calendar_ {
			continue
		}

		if list_type == 'by_title' {
			filename := texttools.name_fix(event.title) + '.json'
			metadata := vfs.Metadata{
				id:          u32(event.id)
				name:        filename
				file_type:   .file
				size:        u64(json.encode(event).len)
				created_at:  event.start_time.time().unix()
				modified_at: event.start_time.time().unix()
				accessed_at: time.now().unix()
			}
			result << CalendarFSEntry{
				path:     '${calendar_}/by_title/${filename}'
				metadata: metadata
				calendar: event
			}
		} else if list_type == 'by_organizer' {
			if event.organizer.len > 0 {
				filename := texttools.name_fix(event.organizer) + '.json'
				metadata := vfs.Metadata{
					id:          u32(event.id)
					name:        filename
					file_type:   .file
					size:        u64(json.encode(event).len)
					created_at:  event.start_time.time().unix()
					modified_at: event.start_time.time().unix()
					accessed_at: time.now().unix()
				}
				result << CalendarFSEntry{
					path:     '${calendar_}/by_organizer/${filename}'
					metadata: metadata
					calendar: event
				}
			}
		}
	}

	return result
}
