module heromodels

import crypto.blake3
import json

// FsSymlink represents a symbolic link in a filesystem
@[heap]
pub struct FsSymlink {
pub mut:
    id         string     // blake192 hash
    name       string
    fs_id      string     // Associated filesystem
    parent_id  string     // Parent directory ID
    target_id  string     // ID of target file or directory
    target_type SymlinkTargetType
    created_at i64
    updated_at i64
    tags       []string
}

pub enum SymlinkTargetType {
    file
    directory
}

pub fn (mut s FsSymlink) calculate_id() {
    content := json.encode(SymlinkContent{
        name: s.name
        fs_id: s.fs_id
        parent_id: s.parent_id
        target_id: s.target_id
        target_type: s.target_type
        tags: s.tags
    })
    hash := blake3.sum256(content.bytes())
    s.id = hash.hex()[..48]
}

struct SymlinkContent {
    name        string
    fs_id       string
    parent_id   string
    target_id   string
    target_type SymlinkTargetType
    tags        []string
}

pub fn new_fs_symlink(name string, fs_id string, parent_id string, target_id string, target_type SymlinkTargetType) FsSymlink {
    mut symlink := FsSymlink{
        name: name
        fs_id: fs_id
        parent_id: parent_id
        target_id: target_id
        target_type: target_type
        created_at: time.now().unix_time()
        updated_at: time.now().unix_time()
    }
    symlink.calculate_id()
    return symlink
}