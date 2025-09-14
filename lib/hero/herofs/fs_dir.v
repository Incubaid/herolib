module herofs

import time
import crypto.blake3
import json
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// FsDir represents a directory in a filesystem
@[heap]
pub struct FsDir {
	db.Base
pub mut:
	name      string
	fs_id     u32 // Associated filesystem
	parent_id u32 // Parent directory ID (0 for root)
}

// we only keep the parents, not the children, as children can be found by doing a query on parent_id, we will need some smart hsets to make this fast enough and efficient

pub struct DBFsDir {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self FsDir) type_name() string {
	return 'fs_dir'
}

pub fn (self FsDir) dump(mut e encoder.Encoder) ! {
	e.add_string(self.name)
	e.add_u32(self.fs_id)
	e.add_u32(self.parent_id)
}

fn (mut self DBFsDir) load(mut o FsDir, mut e encoder.Decoder) ! {
	o.name = e.get_string()!
	o.fs_id = e.get_u32()!
	o.parent_id = e.get_u32()!
}

@[params]
pub struct FsDirArg {
pub mut:
	name        string @[required]
	description string
	fs_id       u32 @[required]
	parent_id   u32
	tags        []string
	comments    []db.CommentArg
}

// get new directory, not from the DB
pub fn (mut self DBFsDir) new(args FsDirArg) !FsDir {
	mut o := FsDir{
		name:      args.name
		fs_id:     args.fs_id
		parent_id: args.parent_id
	}

	// Set base fields
	o.description = args.description
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBFsDir) set(o FsDir) !u32 {
	id := self.db.set[FsDir](o)!

	// Store directory in filesystem's directory index
	path_key := '${o.fs_id}:${o.parent_id}:${o.name}'
	self.db.redis.hset('fsdir:paths', path_key, id.str())!

	// Store in filesystem's directory list using hset
	self.db.redis.hset('fsdir:fs:${o.fs_id}', id.str(), id.str())!

	// Store in parent's children list using hset
	if o.parent_id > 0 {
		self.db.redis.hset('fsdir:children:${o.parent_id}', id.str(), id.str())!
	}

	return id
}

pub fn (mut self DBFsDir) delete(id u32) ! {
	// Get the directory info before deleting
	dir := self.get(id)!

	// Check if directory has children using hkeys
	children := self.db.redis.hkeys('fsdir:children:${id}')!
	if children.len > 0 {
		return error('Cannot delete directory ${dir.name} (ID: ${id}) because it has ${children.len} children')
	}

	// Remove from path index
	path_key := '${dir.fs_id}:${dir.parent_id}:${dir.name}'
	self.db.redis.hdel('fsdir:paths', path_key)!

	// Remove from filesystem's directory list using hdel
	self.db.redis.hdel('fsdir:fs:${dir.fs_id}', id.str())!

	// Remove from parent's children list using hdel
	if dir.parent_id > 0 {
		self.db.redis.hdel('fsdir:children:${dir.parent_id}', id.str())!
	}

	// Delete the directory itself
	self.db.delete[FsDir](id)!
}

pub fn (mut self DBFsDir) exist(id u32) !bool {
	return self.db.exists[FsDir](id)!
}

pub fn (mut self DBFsDir) get(id u32) !FsDir {
	mut o, data := self.db.get_data[FsDir](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBFsDir) list() ![]FsDir {
	return self.db.list[FsDir]()!.map(self.get(it)!)
}

// Get directory by path components
pub fn (mut self DBFsDir) get_by_path(fs_id u32, parent_id u32, name string) !FsDir {
	path_key := '${fs_id}:${parent_id}:${name}'
	id_str := self.db.redis.hget('fsdir:paths', path_key)!
	if id_str == '' {
		return error('Directory "${name}" not found in filesystem ${fs_id} under parent ${parent_id}')
	}
	return self.get(id_str.u32())!
}

// Get all directories in a filesystem
pub fn (mut self DBFsDir) list_by_filesystem(fs_id u32) ![]FsDir {
	dir_ids := self.db.redis.hkeys('fsdir:fs:${fs_id}')!
	mut dirs := []FsDir{}
	for id_str in dir_ids {
		dirs << self.get(id_str.u32())!
	}
	return dirs
}

// Get children of a directory
pub fn (mut self DBFsDir) list_children(dir_id u32) ![]FsDir {
	child_ids := self.db.redis.hkeys('fsdir:children:${dir_id}')!
	mut dirs := []FsDir{}
	for id_str in child_ids {
		dirs << self.get(id_str.u32())!
	}
	return dirs
}

// Check if a directory has children
pub fn (mut self DBFsDir) has_children(dir_id u32) !bool {
	keys := self.db.redis.hkeys('fsdir:children:${dir_id}')!
	return keys.len > 0
}

// Rename a directory
pub fn (mut self DBFsDir) rename(id u32, new_name string) !u32 {
	mut dir := self.get(id)!

	// Remove old path index
	old_path_key := '${dir.fs_id}:${dir.parent_id}:${dir.name}'
	self.db.redis.hdel('fsdir:paths', old_path_key)!

	// Update name
	dir.name = new_name

	// Save with new name
	return self.set(dir)!
}

// Move a directory to a new parent
pub fn (mut self DBFsDir) move(id u32, new_parent_id u32) !u32 {
	mut dir := self.get(id)!

	// Check that new parent exists and is in the same filesystem
	if new_parent_id > 0 {
		parent := self.get(new_parent_id)!
		if parent.fs_id != dir.fs_id {
			return error('Cannot move directory across filesystems')
		}
	}

	// Remove old path index
	old_path_key := '${dir.fs_id}:${dir.parent_id}:${dir.name}'
	self.db.redis.hdel('fsdir:paths', old_path_key)!

	// Remove from old parent's children list
	if dir.parent_id > 0 {
		self.db.redis.hdel('fsdir:children:${dir.parent_id}', id.str())!
	}

	// Update parent
	dir.parent_id = new_parent_id

	// Save with new parent
	return self.set(dir)!
}
