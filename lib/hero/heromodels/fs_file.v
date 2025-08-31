module heromodels

import time
import crypto.blake3
import json

// FsFile represents a file in a filesystem
@[heap]
pub struct FsFile {
pub mut:
    id          string   // blake192 hash
    name        string
    fs_id       string   // Associated filesystem
    directories []string // Directory IDs where this file exists
    blobs       []string // Blake192 IDs of file content blobs
    size_bytes  i64      // Total file size
    mime_type   string
    checksum    string   // Overall file checksum
    created_at  i64
    updated_at  i64
    accessed_at i64
    tags        []string
    metadata    map[string]string // Custom metadata
}

pub fn (mut f FsFile) calculate_id() {
    content := json.encode(FileContent{
        name: f.name
        fs_id: f.fs_id
        directories: f.directories
        blobs: f.blobs
        size_bytes: f.size_bytes
        mime_type: f.mime_type
        checksum: f.checksum
        tags: f.tags
        metadata: f.metadata
    })
    hash := blake3.sum256(content.bytes())
    f.id = hash.hex()[..48]
}

struct FileContent {
    name        string
    fs_id       string
    directories []string
    blobs       []string
    size_bytes  i64
    mime_type   string
    checksum    string
    tags        []string
    metadata    map[string]string
}

pub fn new_fs_file(name string, fs_id string, directories []string) FsFile {
    mut file := FsFile{
        name: name
        fs_id: fs_id
        directories: directories
        created_at: time.now().unix()
        updated_at: time.now().unix()
        accessed_at: time.now().unix()
    }
    file.calculate_id()
    return file
}