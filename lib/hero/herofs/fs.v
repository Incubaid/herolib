module herofs

import time
import crypto.blake3
import json
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Fs represents a filesystem, is the top level container for files and directories and symlinks, blobs are used over filesystems
@[heap]
pub struct Fs {
	db.Base
pub mut:
	name        string
	group_id    u32 // Associated group for permissions
	root_dir_id u32 // ID of root directory
	quota_bytes u64 // Storage quota in bytes
	used_bytes  u64 // Current usage in bytes
}

// We only keep the root directory ID here, other directories can be found by querying parent_id in FsDir

pub struct DBFs {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Fs) type_name() string {
	return 'fs'
}

pub fn (self Fs) dump(mut e &encoder.Encoder) ! {
	e.add_string(self.name)
	e.add_u32(self.group_id)
	e.add_u32(self.root_dir_id)
	e.add_u64(self.quota_bytes)
	e.add_u64(self.used_bytes)
}

fn (mut self DBFs) load(mut o Fs, mut e &encoder.Decoder) ! {
	o.name = e.get_string()!
	o.group_id = e.get_u32()!
	o.root_dir_id = e.get_u32()!
	o.quota_bytes = e.get_u64()!
	o.used_bytes = e.get_u64()!
}

@[params]
pub struct FsArg {
pub mut:
	name        string @[required]
	description string
	group_id    u32
	root_dir_id u32
	quota_bytes u64
	used_bytes  u64
	tags        []string
	comments    []db.CommentArg
}

// get new filesystem, not from the DB
pub fn (mut self DBFs) new(args FsArg) !Fs {
	mut o := Fs{
		name:        args.name
		group_id:    args.group_id
		root_dir_id: args.root_dir_id
		quota_bytes: args.quota_bytes
		used_bytes:  args.used_bytes
	}
	
	// Set base fields
	o.description = args.description
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
	o.updated_at = ourtime.now().unix()
	
	return o
}

pub fn (mut self DBFs) set(o Fs) !u32 {
	id := self.db.set[Fs](o)!
	
	// Store name -> id mapping for lookups
	self.db.redis.hset('fs:names', o.name, id.str())!
	
	return id
}

pub fn (mut self DBFs) delete(id u32) ! {
	// Get the filesystem to retrieve its name
	fs := self.get(id)!
	
	// Remove name -> id mapping
	self.db.redis.hdel('fs:names', fs.name)!
	
	// Delete the filesystem
	self.db.delete[Fs](id)!
}

pub fn (mut self DBFs) exist(id u32) !bool {
	return self.db.exists[Fs](id)!
}

pub fn (mut self DBFs) get(id u32) !Fs {
	mut o, data := self.db.get_data[Fs](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBFs) list() ![]Fs {
	return self.db.list[Fs]()!.map(self.get(it)!)
}

// Additional hset operations for efficient lookups
pub fn (mut self DBFs) get_by_name(name string) !Fs {
	// We'll store a mapping of name -> id in a separate hash
	id_str := self.db.redis.hget('fs:names', name)!
	if id_str == '' {
		return error('Filesystem with name "${name}" not found')
	}
	return self.get(id_str.u32())!
}

// Custom method to increase used_bytes
pub fn (mut self DBFs) increase_usage(id u32, bytes u64) !u64 {
	mut fs := self.get(id)!
	fs.used_bytes += bytes
	self.set(fs)!
	return fs.used_bytes
}

// Custom method to decrease used_bytes
pub fn (mut self DBFs) decrease_usage(id u32, bytes u64) !u64 {
	mut fs := self.get(id)!
	if bytes > fs.used_bytes {
		fs.used_bytes = 0
	} else {
		fs.used_bytes -= bytes
	}
	self.set(fs)!
	return fs.used_bytes
}

// Check if quota is exceeded
pub fn (mut self DBFs) check_quota(id u32, additional_bytes u64) !bool {
	fs := self.get(id)!
	return (fs.used_bytes + additional_bytes) <= fs.quota_bytes
}