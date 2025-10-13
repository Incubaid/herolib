module vfs_calendar

import incubaid.herolib.vfs
import incubaid.herolib.circles.mcc.db as core

// new creates a new calendar_db VFS instance
pub fn new(calendar_db &core.CalendarDB) !vfs.VFSImplementation {
	return new_calendar_vfs(calendar_db)!
}
