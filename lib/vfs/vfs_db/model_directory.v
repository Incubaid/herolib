module vfs_db

import incubaid.herolib.vfs

// Directory represents a directory in the virtual filesystem
pub struct Directory {
pub mut:
	metadata  vfs.Metadata // vfs.Metadata from models_common.v
	children  []u32        // List of child entry IDs (instead of actual entries)
	parent_id u32          // ID of parent directory (0 for root)
}

fn (d &Directory) get_metadata() vfs.Metadata {
	return d.metadata
}

// is_dir returns true if the entry is a directory
pub fn (d &Directory) is_dir() bool {
	return d.metadata.file_type == .directory
}

// is_file returns true if the entry is a file
pub fn (d &Directory) is_file() bool {
	return d.metadata.file_type == .file
}

// is_symlink returns true if the entry is a symlink
pub fn (d &Directory) is_symlink() bool {
	return d.metadata.file_type == .symlink
}
