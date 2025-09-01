module heromodels

import time
import crypto.blake3

// FsBlob represents binary data up to 1MB
@[heap]
pub struct FsBlob {
pub mut:
    id         string // blake192 hash of content
    data       []u8   // Binary data (max 1MB)
    size_bytes int    // Size in bytes
    created_at i64
    mime_type  string
    encoding   string // e.g., "gzip", "none"
}

pub fn (mut b FsBlob) calculate_id() {
    hash := blake3.sum256(b.data)
    b.id = hash.hex()[..48] // blake192 = first 192 bits = 48 hex chars
}

pub fn new_fs_blob(data []u8) !FsBlob {
    if data.len > 1024 * 1024 { // 1MB limit
        return error('Blob size exceeds 1MB limit')
    }
    
    mut blob := FsBlob{
        data: data
        size_bytes: data.len
        created_at: time.now().unix()
        encoding: 'none'
    }
    blob.calculate_id()
    return blob
}

pub fn (b FsBlob) verify_integrity() bool {
    hash := blake3.sum256(b.data)
    return hash.hex()[..48] == b.id
}