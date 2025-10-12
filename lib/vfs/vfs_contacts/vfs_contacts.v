module vfs_contacts

import incubaid.herolib.vfs
import incubaid.herolib.circles.mcc.db as core
// import incubaid.herolib.circles.mcc.models as mcc

// ContactsVFS represents the virtual file system for contacts
pub struct ContactsVFS {
pub mut:
	contacts_db &core.ContactsDB // Reference to the contacts database
}

// new_contacts_vfs creates a new contacts VFS
pub fn new_contacts_vfs(contacts_db &core.ContactsDB) !vfs.VFSImplementation {
	return &ContactsVFS{
		contacts_db: contacts_db
	}
}
