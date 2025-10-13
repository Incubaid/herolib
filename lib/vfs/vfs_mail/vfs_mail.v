module vfs_mail

import incubaid.herolib.vfs
import incubaid.herolib.circles.mcc.db as core

// MailVFS implements the VFS interface for mail objects
pub struct MailVFS {
pub mut:
	mail_db &core.MailDB
}

// new_mail_vfs creates a new mail VFS
pub fn new_mail_vfs(mail_db &core.MailDB) !vfs.VFSImplementation {
	return &MailVFS{
		mail_db: mail_db
	}
}
