module herofs

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

	self.db.set[FsSymlink](o)!
	return o
}

pub fn (mut self DBFsSymlink) delete(id u32) ! {
	// Get the symlink info before deleting
	symlink := self.get(id)!

	// Remove from parent directory's symlinks list
	if symlink.parent_id > 0 {
		mut parent_dir := self.factory.fs_dir.get(symlink.parent_id)!
		parent_dir.symlinks = parent_dir.symlinks.filter(it != id)
		self.factory.fs_dir.set(mut parent_dir)!
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
