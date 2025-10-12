module vfs_local

import os
import incubaid.herolib.vfs

// Convert path to vfs.Metadata with improved security and information gathering
fn (myvfs LocalVFS) os_attr_to_metadata(path string) !vfs.Metadata {
	// Get file info atomically to prevent TOCTOU issues
	attr := os.stat(path) or { return error('Failed to get file attributes: ${err}') }

	mut file_type := vfs.FileType.file
	if os.is_dir(path) {
		file_type = .directory
	} else if os.is_link(path) {
		file_type = .symlink
	}

	return vfs.Metadata{
		id:          u32(attr.inode) // QUESTION: what should id be here
		name:        os.base(path)
		file_type:   file_type
		size:        u64(attr.size)
		created_at:  i64(attr.ctime) // Creation time from stat
		modified_at: i64(attr.mtime) // Modification time from stat
		accessed_at: i64(attr.atime) // Access time from stat
	}
}

// Get absolute path from relative path
fn (myvfs LocalVFS) abs_path(path string) string {
	return os.join_path(myvfs.root_path, path)
}
