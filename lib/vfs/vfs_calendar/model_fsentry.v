module vfs_calendar

import incubaid.herolib.vfs
import incubaid.herolib.circles.mcc.models as calendars

// CalendarFSEntry represents a file system entry in the calendar VFS
pub struct CalendarFSEntry {
pub mut:
	path     string
	metadata vfs.Metadata
	calendar ?calendars.CalendarEvent
}

// is_dir returns true if the entry is a directory
pub fn (self &CalendarFSEntry) is_dir() bool {
	return self.metadata.file_type == .directory
}

// is_file returns true if the entry is a file
pub fn (self &CalendarFSEntry) is_file() bool {
	return self.metadata.file_type == .file
}

// is_symlink returns true if the entry is a symlink
pub fn (self &CalendarFSEntry) is_symlink() bool {
	return self.metadata.file_type == .symlink
}

// get_metadata returns the entry's metadata
pub fn (e CalendarFSEntry) get_metadata() vfs.Metadata {
	return e.metadata
}

// get_path returns the entry's path
pub fn (e CalendarFSEntry) get_path() string {
	return e.path
}
