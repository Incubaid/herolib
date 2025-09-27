// Replace the current content with:
module herofs

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.core.redisclient

@[heap]
pub struct FSFactory {
pub mut:
	fs                 DBFs
	fs_blob            DBFsBlob
	fs_blob_membership DBFsBlobMembership
	fs_dir             DBFsDir
	fs_file            DBFsFile
	fs_symlink         DBFsSymlink
}

@[params]
pub struct DBArgs {
pub mut:
	redis ?&redisclient.Redis
}

pub fn new(args DBArgs) !FSFactory {
	mut mydb := db.new(redis: args.redis)!
	mut f := FSFactory{
		fs:                 DBFs{
			db: &mydb
		}
		fs_blob:            DBFsBlob{
			db: &mydb
		}
		fs_blob_membership: DBFsBlobMembership{
			db: &mydb
		}
		fs_dir:             DBFsDir{
			db: &mydb
		}
		fs_file:            DBFsFile{
			db: &mydb
		}
		fs_symlink:         DBFsSymlink{
			db: &mydb
		}
	}
	f.fs.factory = &f
	f.fs_blob.factory = &f
	f.fs_blob_membership.factory = &f
	f.fs_dir.factory = &f
	f.fs_file.factory = &f
	f.fs_symlink.factory = &f
	return f
}

pub fn new_test() !FSFactory {
	mut mydb := db.new_test()!
	mut f := new(redisclient: mydb.redis)!
	f.fs.db.redis.flushdb()!
	return f
}

// Convenience function for creating a filesystem
pub fn new_fs(args FsArg) !Fs {
	mut f := new()!
	return f.fs.new_get_set(args)!
}

pub fn new_fs_test() !Fs {
	mut mydb := db.new_test()!
	mut f := new(redisclient: mydb.redis)!
	f.fs.db.redis.flushdb()!
	return f.fs.new_get_set(name: 'test')!
}

pub fn delete_fs_test() ! {
	mut mydb := db.new_test()!
	mut f := new(redisclient: mydb.redis)!
	f.fs.db.redis.flushdb()!
}
