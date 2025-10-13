module vfs_contacts

import incubaid.herolib.vfs
import incubaid.herolib.circles.mcc.db as core

// new creates a new contacts_db VFS instance
pub fn new(contacts_db &core.ContactsDB) !vfs.VFSImplementation {
	return new_contacts_vfs(contacts_db)!
}
