module herofs

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_ok, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import freeflowuniverse.herolib.ui.console
import json

// Fs represents a filesystem, is the top level container for files and directories and symlinks, blobs are used over filesystems
@[heap]
pub struct Fs {
	db.Base
pub mut:
	root_dir_id u32 // ID of root directory
	quota_bytes u64 // Storage quota in bytes
	used_bytes  u64 // Current usage in bytes
	factory     &FSFactory = unsafe { nil } @[skip; str: skip]
}

// We only keep the root directory ID here, other directories can be found by querying parent_id in FsDir

pub struct DBFs {
pub mut:
	db      &db.DB     @[skip; str: skip]
	factory &FSFactory = unsafe { nil } @[skip; str: skip]
}

pub fn (self Fs) type_name() string {
	return 'fs'
}

// return example rpc call and result for each methodname
pub fn (self Fs) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a filesystem. Returns the ID of the filesystem.'
		}
		'get' {
			return 'Retrieve a filesystem by ID. Returns the filesystem object.'
		}
		'delete' {
			return 'Delete a filesystem by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a filesystem exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all filesystems. Returns an array of filesystem objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self Fs) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"fs": {"name": "myfs", "description": "My filesystem", "quota_bytes": 1073741824}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "myfs", "description": "My filesystem", "quota_bytes": 1073741824, "used_bytes": 0}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "myfs", "description": "My filesystem", "quota_bytes": 1073741824, "used_bytes": 0}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Fs) dump(mut e encoder.Encoder) ! {
	// e.add_string(self.name)
	e.add_u32(self.root_dir_id)
	e.add_u64(self.quota_bytes)
	e.add_u64(self.used_bytes)
}

fn (mut self DBFs) load(mut o Fs, mut e encoder.Decoder) ! {
	// o.name = e.get_string()!
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
	messages    []db.MessageArg
}

@[params]
pub struct FsListArg {
pub mut:
	limit int = 100 // Default limit is 100
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
	// o.factory = self.factory
	return o
}

pub fn (mut self DBFs) list(args FsListArg) ![]Fs {
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

// Note: Filesystem usage tracking methods are not implemented yet
// These would be used for quota enforcement and storage monitoring
// Future implementation should use separate Redis structures for performance

// Check if quota is exceeded
pub fn (mut self DBFs) check_quota(id u32, additional_bytes u64) !bool {
	fs := self.get(id)!
	return (fs.used_bytes + additional_bytes) <= fs.quota_bytes
}

pub fn fs_handle(mut f FSFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.fs.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut o := db.decode_generic[Fs](params)!
			o = f.fs.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			f.fs.delete(id)!
			return new_response_ok(rpcid)
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.fs.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			args := db.decode_generic[FsListArg](params)!
			res := f.fs.list(args)!
			return new_response(rpcid, json.encode(res))
		}
		else {
			console.print_stderr('Method not found on fs: ${method}')
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on fs'
			)
		}
	}
}
