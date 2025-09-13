module herofs

import time
import crypto.blake3
import json

// FsSymlink represents a symbolic link in a filesystem
@[heap]
pub struct FsSymlink {
pub mut:
	name        string
	fs_id       u32 // Associated filesystem
	parent_id   u32 // Parent directory ID
	target_id   u32 // ID of target file or directory
	target_type SymlinkTargetType
}

pub enum SymlinkTargetType {
	file
	directory
}

