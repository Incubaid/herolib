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
	fs_id     u32 // Associated filesystem
	parent_id u32 // Parent directory ID (0 for root)
	directories []u32
	files       []u32
	symlinks    []u32
}

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
	return id
}

pub fn (mut self DBFsDir) delete(id u32) ! {
	// Get the directory info before deleting
	dir := self.get(id)!
	//TODO: now remove myself from parent dir too
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

// THERE IS NO LIST FUNCTION AS DIRECTORIES ARE ALWAYS KNOWN FROM THE FS, the FS points to the root directory by id