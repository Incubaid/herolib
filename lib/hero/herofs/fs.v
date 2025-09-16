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
	root_dir_id u32 // ID of root directory
	quota_bytes u64 // Storage quota in bytes
	used_bytes  u64 // Current usage in bytes
}

// We only keep the root directory ID here, other directories can be found by querying parent_id in FsDir

pub struct DBFs {
pub mut:
	db      &db.DB     @[skip; str: skip]
	factory &FsFactory = unsafe { nil } @[skip; str: skip]
}

pub fn (self Fs) type_name() string {
	return 'fs'
}

pub fn (self Fs) dump(mut e encoder.Encoder) ! {
	e.add_string(self.name)
	e.add_u32(self.root_dir_id)
	e.add_u64(self.quota_bytes)
	e.add_u64(self.used_bytes)
}

fn (mut self DBFs) load(mut o Fs, mut e encoder.Decoder) ! {
	o.name = e.get_string()!
	o.root_dir_id = e.get_u32()!
	o.quota_bytes = e.get_u64()!
	o.used_bytes = e.get_u64()!
}

@[params]
pub struct FsArg {
pub mut:
	name        string @[required]
	description string
	root_dir_id u32
	quota_bytes u64
	used_bytes  u64
	tags        []string
	comments    []db.CommentArg
}

// get new filesystem, if it exists then it will get it from the DB
pub fn (mut self DBFs) new_get_set(args_ FsArg) !Fs {
	mut args := args_
	args.name = args.name.trim_space().to_lower()

	mut o := Fs{
		name: args.name
	}

	myid := self.db.redis.hget('fs:names', args.name)!
	mut changes := true

	if myid != '' {
		o = self.get(myid.u32())!
		changes = false
	}

	if args.description != '' {
		o.description = args.description
		changes = true
	}
	if args.root_dir_id != 0 {
		o.root_dir_id = args.root_dir_id
		changes = true
	}
	if args.quota_bytes != 0 {
		o.quota_bytes = args.quota_bytes
		changes = true
	} else {
		o.quota_bytes = 1024 * 1024 * 1024 * 100 // Default to 100GB
	}
	if args.used_bytes != 0 {
		changes = true
		o.used_bytes = args.used_bytes
	}
	if args.tags.len > 0 {
		o.tags = self.db.tags_get(args.tags)!
		changes = true
	}
	if args.comments.len > 0 {
		o.comments = self.db.comments_get(args.comments)!
		changes = true
	}

	if changes {
		self.set(mut o)!
	}

	return o
}

pub fn (mut self DBFs) set(o Fs) !Fs {
	mut o_mut := o
	if o_mut.root_dir_id == 0 {
		// If no root directory is set, create one
		mut root_dir := self.factory.fs_dir.new(
			name:      'root'
			fs_id:     o_mut.id
			parent_id: 0 // Root has no parent
		)!
		root_dir = self.factory.fs_dir.set(root_dir)!
		o_mut.root_dir_id = root_dir.id
		// Update the filesystem with the new root directory ID
	}
	self.db.redis.hset('fs:names', o_mut.name, o_mut.id.str())!
	// Use db set function which now modifies the object in-place	
	self.db.set[Fs](o_mut)!
	return o_mut
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

// TODO: need to redo, in separate struct in redis, like this will be too heavy
// // Custom method to increase used_bytes
// pub fn (mut self DBFs) increase_usage(id u32, bytes u64) !u64 {
// 	mut fs := self.get(id)!
// 	fs.used_bytes += bytes
// 	self.set(mut fs)!
// 	return fs.used_bytes
// }

// // Custom method to decrease used_bytes
// pub fn (mut self DBFs) decrease_usage(id u32, bytes u64) !u64 {
// 	mut fs := self.get(id)!
// 	if bytes > fs.used_bytes {
// 		fs.used_bytes = 0
// 	} else {
// 		fs.used_bytes -= bytes
// 	}
// 	self.set(mut fs)!
// 	return fs.used_bytes
// }

// Check if quota is exceeded
pub fn (mut self DBFs) check_quota(id u32, additional_bytes u64) !bool {
	fs := self.get(id)!
	return (fs.used_bytes + additional_bytes) <= fs.quota_bytes
}
