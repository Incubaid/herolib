module heromodels

import time
import crypto.blake3
import json

// Fs represents a filesystem namespace
@[heap]
pub struct Fs {
pub mut:
	id          string // blake192 hash
	name        string
	description string
	group_id    string // Associated group for permissions
	root_dir_id string // ID of root directory
	created_at  i64
	updated_at  i64
	quota_bytes i64 // Storage quota in bytes
	used_bytes  i64 // Current usage in bytes
	tags        []string
}

pub fn (mut f Fs) calculate_id() {
	content := json.encode(FsContent{
		name:        f.name
		description: f.description
		group_id:    f.group_id
		quota_bytes: f.quota_bytes
		tags:        f.tags
	})
	hash := blake3.sum256(content.bytes())
	f.id = hash.hex()[..48]
}

struct FsContent {
	name        string
	description string
	group_id    string
	quota_bytes i64
	tags        []string
}

pub fn new_fs(name string, group_id string) Fs {
	mut fs := Fs{
		name:       name
		group_id:   group_id
		created_at: time.now().unix()
		updated_at: time.now().unix()
	}
	fs.calculate_id()
	return fs
}
