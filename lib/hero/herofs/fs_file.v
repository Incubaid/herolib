module herofs

import time
import crypto.blake3
import json

// FsFile represents a file in a filesystem
@[heap]
pub struct FsFile {
pub mut:
	name        string
	fs_id       string   // Associated filesystem
	directories []u32 // Directory IDs where this file exists, means file can be part of multiple directories (like hard links in Linux)
	blobs       []u32 // Blake192 IDs of file content blobs (we reference them with u32 IDs for efficiency)
	size_bytes  u64    
	mime_type   string   // e.g., "image/png"
	checksum    string   // e.g., SHA256 checksum of the file
	accessed_at i64
	metadata    map[string]string // Custom metadata
}

