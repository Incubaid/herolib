module vfs_contacts

import incubaid.herolib.vfs
import incubaid.herolib.circles.mcc.models as contacts

// ContactsFSEntry implements FSEntry for contacts objects
pub struct ContactsFSEntry {
pub mut:
	path     string
	metadata vfs.Metadata
	contact  ?contacts.Contact
}

// is_dir returns true if the entry is a directory
pub fn (self &ContactsFSEntry) is_dir() bool {
	return self.metadata.file_type == .directory
}

// is_file returns true if the entry is a file
pub fn (self &ContactsFSEntry) is_file() bool {
	return self.metadata.file_type == .file
}

// is_symlink returns true if the entry is a symlink
pub fn (self &ContactsFSEntry) is_symlink() bool {
	return self.metadata.file_type == .symlink
}

pub fn (e ContactsFSEntry) get_metadata() vfs.Metadata {
	return e.metadata
}

pub fn (e ContactsFSEntry) get_path() string {
	return e.path
}
