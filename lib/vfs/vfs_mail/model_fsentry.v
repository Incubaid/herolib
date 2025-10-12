module vfs_mail

import incubaid.herolib.vfs
import incubaid.herolib.circles.mcc.models as mail

// MailFSEntry implements FSEntry for mail objects
pub struct MailFSEntry {
pub mut:
	path     string
	metadata vfs.Metadata
	email    ?mail.Email
}

// is_dir returns true if the entry is a directory
pub fn (self &MailFSEntry) is_dir() bool {
	return self.metadata.file_type == .directory
}

// is_file returns true if the entry is a file
pub fn (self &MailFSEntry) is_file() bool {
	return self.metadata.file_type == .file
}

// is_symlink returns true if the entry is a symlink
pub fn (self &MailFSEntry) is_symlink() bool {
	return self.metadata.file_type == .symlink
}

pub fn (e MailFSEntry) get_metadata() vfs.Metadata {
	return e.metadata
}

pub fn (e MailFSEntry) get_path() string {
	return e.path
}
