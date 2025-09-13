module herofs

import time
import crypto.blake3
import json

// FsDir represents a directory in a filesystem
@[heap]
pub struct FsDir {
pub mut:
	name       string
	fs_id      u32   // Associated filesystem
	parent_id  u32   // Parent directory ID (empty for root)
}

//we only keep the parents, not the children, as children can be found by doing a query on parent_id, we will need some smart hsets to make this fast enough and efficient