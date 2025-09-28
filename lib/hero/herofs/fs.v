module herofs

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
	factory     &FsFactory = unsafe { nil } @[skip; str: skip]
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
	e.add_u32(self.group_id)
	e.add_u32(self.root_dir_id)
	e.add_u64(self.quota_bytes)
	e.add_u64(self.used_bytes)
}

fn (mut self DBFs) load(mut o Fs, mut e encoder.Decoder) ! {
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
	messages    []db.MessageArg
}

// get new filesystem, not from the DB
pub fn (mut self DBFs) new(args FsArg) !Fs {
	mut o := Fs{
		name:    args.name
		factory: self.factory
	}

	if args.description != '' {
		o.description = args.description
	}
	if args.group_id != 0 {
		o.group_id = args.group_id
	}
	if args.root_dir_id != 0 {
		o.root_dir_id = args.root_dir_id
	}
	if args.quota_bytes != 0 {
		o.quota_bytes = args.quota_bytes
	} else {
		o.quota_bytes = 1024 * 1024 * 1024 * 100 // Default to 100GB
	}
	if args.used_bytes != 0 {
		o.used_bytes = args.used_bytes
	}
	if args.tags.len > 0 {
		o.tags = self.db.tags_get(args.tags)!
	}
	if args.messages.len > 0 {
		o.messages = self.db.messages_get(args.messages)!
	}

	return o
}

// get new filesystem, if it exists then it will get it from the DB
pub fn (mut self DBFs) new_get_set(args_ FsArg) !Fs {
	mut args := args_
	args.name = args.name.trim_space().to_lower()

	mut o := Fs{
		name:    args.name
		factory: self.factory
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
	if args.messages.len > 0 {
		o.messages = self.db.messages_get(args.messages)!
		changes = true
	}

	if changes {
		o = self.set(o)!
	}

	return o
}

pub fn (mut self DBFs) set(o Fs) !Fs {
	mut o_mut := o
	if o_mut.id == 0 {
		o_mut.id = self.db.new_id()!
	}
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
	// Use db set function which now modifies the object in-place
	o_result := self.db.set[Fs](o_mut)!
	self.db.redis.hset('fs:names', o_result.name, o_result.id.str())!
	return o_result
}

pub fn (mut self Fs) root_dir() !FsDir {
	mut o := self.factory.fs_dir.get(self.root_dir_id) or {
		return error("Can't find root_dir\n${err}")
	}
	return o
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
	o.factory = self.factory
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

// Increase used bytes counter
pub fn (mut self DBFs) increase_usage(id u32, bytes u64) ! {
	mut fs := self.get(id)!
	fs.used_bytes += bytes
	fs.updated_at = ourtime.now().unix()
	self.set(fs)!
}

// Decrease used bytes counter
pub fn (mut self DBFs) decrease_usage(id u32, bytes u64) ! {
	mut fs := self.get(id)!
	if fs.used_bytes >= bytes {
		fs.used_bytes -= bytes
	} else {
		fs.used_bytes = 0
	}
	fs.updated_at = ourtime.now().unix()
	self.set(fs)!
}

// Check if quota is exceeded
pub fn (mut self DBFs) check_quota(id u32, additional_bytes u64) !bool {
	fs := self.get(id)!
	return (fs.used_bytes + additional_bytes) <= fs.quota_bytes
}
