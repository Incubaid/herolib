module vfs_db

import incubaid.herolib.vfs

// Symlink represents a symbolic link in the virtual filesystem
pub struct Symlink {
pub mut:
	metadata  vfs.Metadata // vfs.Metadata from models_common.v
	target    string       // Path that this symlink points to
	parent_id u32          // ID of parent directory
}

// update_target changes the symlink's target path
pub fn (mut sl Symlink) update_target(new_target string) ! {
	sl.target = new_target
	sl.metadata.modified()
}

// get_target returns the current target path
pub fn (mut sl Symlink) get_target() !string {
	sl.metadata.accessed()
	return sl.target
}

fn (s &Symlink) get_metadata() vfs.Metadata {
	return s.metadata
}

// is_dir returns true if the entry is a directory
pub fn (self &Symlink) is_dir() bool {
	return self.metadata.file_type == .directory
}

// is_file returns true if the entry is a file
pub fn (self &Symlink) is_file() bool {
	return self.metadata.file_type == .file
}

// is_symlink returns true if the entry is a symlink
pub fn (self &Symlink) is_symlink() bool {
	return self.metadata.file_type == .symlink
}
