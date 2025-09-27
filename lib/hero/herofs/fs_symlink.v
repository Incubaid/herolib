module herofs

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_ok, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import freeflowuniverse.herolib.ui.console
import json

// FsSymlink represents a symbolic link in a filesystem
@[heap]
pub struct FsSymlink {
	db.Base
pub mut:
	fs_id       u32 // Associated filesystem
	parent_id   u32 // Parent directory ID
	target_id   u32 // ID of target file or directory
	target_type SymlinkTargetType
}

pub enum SymlinkTargetType {
	file
	directory
}

pub struct DBFsSymlink {
pub mut:
	db      &db.DB     @[skip; str: skip]
	factory &FSFactory = unsafe { nil } @[skip; str: skip]
}

pub fn (self FsSymlink) type_name() string {
	return 'fs_symlink'
}

pub fn (self FsSymlink) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.fs_id)
	e.add_u32(self.parent_id)
	e.add_u32(self.target_id)
	e.add_u8(u8(self.target_type))
}

fn (mut self DBFsSymlink) load(mut o FsSymlink, mut e encoder.Decoder) ! {
	o.fs_id = e.get_u32()!
	o.parent_id = e.get_u32()!
	o.target_id = e.get_u32()!
	o.target_type = unsafe { SymlinkTargetType(e.get_u8()!) }
}

@[params]
pub struct FsSymlinkArg {
pub mut:
	name        string @[required]
	description string
	fs_id       u32               @[required]
	parent_id   u32               @[required]
	target_id   u32               @[required]
	target_type SymlinkTargetType @[required]
	tags        []string
	comments    []db.CommentArg
}

// get new symlink, not from the DB
pub fn (mut self DBFsSymlink) new(args FsSymlinkArg) !FsSymlink {
	mut o := FsSymlink{
		name:        args.name
		fs_id:       args.fs_id
		parent_id:   args.parent_id
		target_id:   args.target_id
		target_type: args.target_type
	}

	// Set base fields
	o.description = args.description
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBFsSymlink) set(o FsSymlink) !FsSymlink {
	// Check parent directory exists
	if o.parent_id > 0 {
		parent_exists := self.db.exists[FsDir](o.parent_id)!
		if !parent_exists {
			return error('Parent directory with ID ${o.parent_id} does not exist')
		}
	}

	// Check target exists based on target type
	if o.target_type == .file {
		target_exists := self.db.exists[FsFile](o.target_id)!
		if !target_exists {
			return error('Target file with ID ${o.target_id} does not exist')
		}
	} else if o.target_type == .directory {
		target_exists := self.db.exists[FsDir](o.target_id)!
		if !target_exists {
			return error('Target directory with ID ${o.target_id} does not exist')
		}
	}

	o_result := self.db.set[FsSymlink](o)!
	return o_result
}

pub fn (mut self DBFsSymlink) delete(id u32) ! {
	// Get the symlink info before deleting
	symlink := self.get(id)!

	// Remove from parent directory's symlinks list
	if symlink.parent_id > 0 {
		mut parent_dir := self.factory.fs_dir.get(symlink.parent_id)!
		parent_dir.symlinks = parent_dir.symlinks.filter(it != id)
		self.factory.fs_dir.set(parent_dir)!
	}

	self.db.delete[FsSymlink](id)!
}

pub fn (mut self DBFsSymlink) exist(id u32) !bool {
	return self.db.exists[FsSymlink](id)!
}

pub fn (mut self DBFsSymlink) get(id u32) !FsSymlink {
	mut o, data := self.db.get_data[FsSymlink](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

// List all symlinks
pub fn (mut self DBFsSymlink) list() ![]FsSymlink {
	ids := self.db.list[FsSymlink]()!
	mut symlinks := []FsSymlink{}
	for id in ids {
		symlinks << self.get(id)!
	}
	return symlinks
}

// List symlinks in a filesystem
pub fn (mut self DBFsSymlink) list_by_filesystem(fs_id u32) ![]FsSymlink {
	all_symlinks := self.list()!
	return all_symlinks.filter(it.fs_id == fs_id)
}

// Check if symlink is broken (target doesn't exist)
pub fn (mut self DBFsSymlink) is_broken(id u32) !bool {
	symlink := self.get(id)!

	if symlink.target_type == .file {
		return !self.db.exists[FsFile](symlink.target_id)!
	} else if symlink.target_type == .directory {
		return !self.db.exists[FsDir](symlink.target_id)!
	}

	return true // Unknown target type is considered broken
}

pub fn (self FsSymlink) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a symlink. Returns the ID of the symlink.'
		}
		'get' {
			return 'Retrieve a symlink by ID. Returns the symlink object.'
		}
		'delete' {
			return 'Delete a symlink by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a symlink exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all symlinks. Returns an array of symlink objects.'
		}
		'is_broken' {
			return 'Check if a symlink is broken. Returns true or false.'
		}
		else {
			return 'This is generic method for the symlink object.'
		}
	}
}

pub fn (self FsSymlink) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"symlink": {"name": "link.txt", "fs_id": 1, "parent_id": 2, "target_id": 3, "target_type": "file"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "link.txt", "fs_id": 1, "parent_id": 2, "target_id": 3, "target_type": "file"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "link.txt", "fs_id": 1, "parent_id": 2, "target_id": 3, "target_type": "file"}]'
		}
		'is_broken' {
			return '{"id": 1}', 'false'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn fs_symlink_handle(mut f FSFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.fs_symlink.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut o := db.decode_generic[FsSymlink](params)!
			o = f.fs_symlink.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			f.fs_symlink.delete(id)!
			return new_response_ok(rpcid)
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.fs_symlink.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			res := f.fs_symlink.list()!
			return new_response(rpcid, json.encode(res))
		}
		'is_broken' {
			id := db.decode_u32(params)!
			is_broken := f.fs_symlink.is_broken(id)!
			if is_broken {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		else {
			console.print_stderr('Method not found on fs_symlink: ${method}')
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on fs_symlink'
			)
		}
	}
}