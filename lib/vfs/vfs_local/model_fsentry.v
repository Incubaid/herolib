module vfs_local

import incubaid.herolib.vfs

// LocalFSEntry implements FSEntry for local filesystem
struct LocalFSEntry {
mut:
	path     string
	metadata vfs.Metadata
}

// is_dir returns true if the entry is a directory
pub fn (self &LocalFSEntry) is_dir() bool {
	return self.metadata.file_type == .directory
}

// is_file returns true if the entry is a file
pub fn (self &LocalFSEntry) is_file() bool {
	return self.metadata.file_type == .file
}

// is_symlink returns true if the entry is a symlink
pub fn (self &LocalFSEntry) is_symlink() bool {
	return self.metadata.file_type == .symlink
}

fn (e LocalFSEntry) get_metadata() vfs.Metadata {
	return e.metadata
}

fn (e LocalFSEntry) get_path() string {
	return e.path
}
