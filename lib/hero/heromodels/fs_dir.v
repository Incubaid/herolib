module heromodels

import time
import crypto.blake3
import json

// FsDir represents a directory in a filesystem
@[heap]
pub struct FsDir {
pub mut:
    id         string   // blake192 hash
    name       string
    fs_id      string   // Associated filesystem
    parent_id  string   // Parent directory ID (empty for root)
    group_id   string   // Associated group for permissions
    children   []string // Child directory and file IDs
    created_at i64
    updated_at i64
    tags       []string
}

pub fn (mut d FsDir) calculate_id() {
    content := json.encode(DirContent{
        name: d.name
        fs_id: d.fs_id
        parent_id: d.parent_id
        group_id: d.group_id
        tags: d.tags
    })
    hash := blake3.sum256(content.bytes())
    d.id = hash.hex()[..48]
}

struct DirContent {
    name      string
    fs_id     string
    parent_id string
    group_id  string
    tags      []string
}

pub fn new_fs_dir(name string, fs_id string, parent_id string, group_id string) FsDir {
    mut dir := FsDir{
        name: name
        fs_id: fs_id
        parent_id: parent_id
        group_id: group_id
        created_at: time.now().unix()
        updated_at: time.now().unix()
    }
    dir.calculate_id()
    return dir
}