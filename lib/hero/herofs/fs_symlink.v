module herofs

import time
import crypto.blake3
import json
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// FsSymlink represents a symbolic link in a filesystem
@[heap]
pub struct FsSymlink {
	db.Base
pub mut:
	name        string
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
	factory &FsFactory = unsafe { nil } @[skip; str: skip]
}

pub fn (self FsSymlink) type_name() string {
	return 'fs_symlink'
}

pub fn (self FsSymlink) dump(mut e encoder.Encoder) ! {
	e.add_string(self.name)
	e.add_u32(self.fs_id)
	e.add_u32(self.parent_id)
	e.add_u32(self.target_id)
	e.add_u8(u8(self.target_type))
}

fn (mut self DBFsSymlink) load(mut o FsSymlink, mut e encoder.Decoder) ! {
	o.name = e.get_string()!
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

pub fn (mut self DBFsSymlink) set(mut o FsSymlink) ! {
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

	self.db.set[FsSymlink](mut o)!

	// Store symlink in parent directory's symlink index
	path_key := '${o.parent_id}:${o.name}'
	self.db.redis.hset('fssymlink:paths', path_key, o.id.str())!

	// Add to parent's symlinks list using hset
	self.db.redis.hset('fssymlink:parent:${o.parent_id}', o.id.str(), o.id.str())!

	// Store in filesystem's symlink list using hset
	self.db.redis.hset('fssymlink:fs:${o.fs_id}', o.id.str(), o.id.str())!

	// Store in target's referrers list using hset
	target_key := '${o.target_type}:${o.target_id}'
	self.db.redis.hset('fssymlink:target:${target_key}', o.id.str(), o.id.str())!
}

pub fn (mut self DBFsSymlink) delete(id u32) ! {
	// Get the symlink info before deleting
	symlink := self.get(id)!

	// Remove from path index
	path_key := '${symlink.parent_id}:${symlink.name}'
	self.db.redis.hdel('fssymlink:paths', path_key)!

	// Remove from parent's symlinks list using hdel
	self.db.redis.hdel('fssymlink:parent:${symlink.parent_id}', id.str())!

	// Remove from filesystem's symlink list using hdel
	self.db.redis.hdel('fssymlink:fs:${symlink.fs_id}', id.str())!

	// Remove from target's referrers list using hdel
	target_key := '${symlink.target_type}:${symlink.target_id}'
	self.db.redis.hdel('fssymlink:target:${target_key}', id.str())!

	// Delete the symlink itself
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

pub fn (mut self DBFsSymlink) list() ![]FsSymlink {
	return self.db.list[FsSymlink]()!.map(self.get(it)!)
}

// Get symlink by path in a parent directory
pub fn (mut self DBFsSymlink) get_by_path(parent_id u32, name string) !FsSymlink {
	path_key := '${parent_id}:${name}'
	id_str := self.db.redis.hget('fssymlink:paths', path_key)!
	if id_str == '' {
		return error('Symlink "${name}" not found in parent directory ${parent_id}')
	}
	return self.get(id_str.u32())!
}

// List symlinks in a parent directory
pub fn (mut self DBFsSymlink) list_by_parent(parent_id u32) ![]FsSymlink {
	symlink_ids := self.db.redis.hkeys('fssymlink:parent:${parent_id}')!
	mut symlinks := []FsSymlink{}
	for id_str in symlink_ids {
		symlinks << self.get(id_str.u32())!
	}
	return symlinks
}

// List symlinks in a filesystem
pub fn (mut self DBFsSymlink) list_by_filesystem(fs_id u32) ![]FsSymlink {
	symlink_ids := self.db.redis.hkeys('fssymlink:fs:${fs_id}')!
	mut symlinks := []FsSymlink{}
	for id_str in symlink_ids {
		symlinks << self.get(id_str.u32())!
	}
	return symlinks
}

// List symlinks pointing to a target
pub fn (mut self DBFsSymlink) list_by_target(target_type SymlinkTargetType, target_id u32) ![]FsSymlink {
	target_key := '${target_type}:${target_id}'
	symlink_ids := self.db.redis.hkeys('fssymlink:target:${target_key}')!
	mut symlinks := []FsSymlink{}
	for id_str in symlink_ids {
		symlinks << self.get(id_str.u32())!
	}
	return symlinks
}

// Rename a symlink
pub fn (mut self DBFsSymlink) rename(id u32, new_name string) !u32 {
	mut symlink := self.get(id)!

	// Remove old path index
	old_path_key := '${symlink.parent_id}:${symlink.name}'
	self.db.redis.hdel('fssymlink:paths', old_path_key)!

	// Update name
	symlink.name = new_name

	// Save with new name
	return self.set(symlink)!
}

// Move symlink to a new parent directory
pub fn (mut self DBFsSymlink) move(id u32, new_parent_id u32) !u32 {
	mut symlink := self.get(id)!

	// Check that new parent exists and is in the same filesystem
	if new_parent_id > 0 {
		parent_data, _ := self.db.get_data[FsDir](new_parent_id)!
		if parent_data.fs_id != symlink.fs_id {
			return error('Cannot move symlink across filesystems')
		}
	}

	// Remove old path index
	old_path_key := '${symlink.parent_id}:${symlink.name}'
	self.db.redis.hdel('fssymlink:paths', old_path_key)!

	// Remove from old parent's symlinks list using hdel
	self.db.redis.hdel('fssymlink:parent:${symlink.parent_id}', id.str())!

	// Update parent
	symlink.parent_id = new_parent_id

	// Save with new parent
	return self.set(symlink)!
}

// Redirect symlink to a new target
pub fn (mut self DBFsSymlink) redirect(id u32, new_target_id u32, new_target_type SymlinkTargetType) !u32 {
	mut symlink := self.get(id)!

	// Check new target exists
	if new_target_type == .file {
		target_exists := self.db.exists[FsFile](new_target_id)!
		if !target_exists {
			return error('Target file with ID ${new_target_id} does not exist')
		}
	} else if new_target_type == .directory {
		target_exists := self.db.exists[FsDir](new_target_id)!
		if !target_exists {
			return error('Target directory with ID ${new_target_id} does not exist')
		}
	}

	// Remove from old target's referrers list
	old_target_key := '${symlink.target_type}:${symlink.target_id}'
	self.db.redis.hdel('fssymlink:target:${old_target_key}', id.str())!

	// Update target
	symlink.target_id = new_target_id
	symlink.target_type = new_target_type

	// Save with new target
	return self.set(symlink)!
}

// Resolve a symlink to get its target
pub fn (mut self DBFsSymlink) resolve(id u32) !u32 {
	symlink := self.get(id)!
	return symlink.target_id
}

// Check if a symlink is broken (target doesn't exist)
pub fn (mut self DBFsSymlink) is_broken(id u32) !bool {
	symlink := self.get(id)!

	if symlink.target_type == .file {
		return !self.db.exists[FsFile](symlink.target_id)!
	} else if symlink.target_type == .directory {
		return !self.db.exists[FsDir](symlink.target_id)!
	}

	return true // Unknown target type is considered broken
}
