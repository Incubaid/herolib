module herofs

import time
import crypto.blake3
import json

// Fs represents a filesystem, is the top level container for files and directories and symlinks, blobs are used over filesystems
@[heap]
pub struct Fs {
pub mut:
	name        string
	group_id    u32 // Associated group for permissions
	root_dir_id u32 // ID of root directory
	quota_bytes u64 // Storage quota in bytes
	used_bytes  u64 // Current usage in bytes
}


// We only keep the root directory ID here, other directories can be found by querying parent_id in FsDir